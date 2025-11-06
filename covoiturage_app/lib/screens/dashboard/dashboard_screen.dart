import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../services/trip_service.dart';
import '../../services/location_tracking_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../trips/trip_creation_wizard.dart';
import '../trips/my_trips_screen.dart';
import '../trips/my_bookings_screen.dart';
import '../rating/rating_screen.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final TripService _tripService = TripService();
  final LocationTrackingService _locationService = LocationTrackingService();
  
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> activeTrips = [];
  Map<int, bool> tripCanEndMap = {}; // tripId -> canEnd
  Map<int, double?> tripDistanceMap = {}; // tripId -> distance in meters
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadActiveTrips();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    await _locationService.startLocationTracking(
      onLocationUpdate: (position) {
        setState(() {
          currentPosition = position;
        });
        _checkActiveTripsDistance();
      },
      onLocationError: (error) {
        debugPrint('Location error: $error');
      },
    );
  }

  Future<void> _loadActiveTrips() async {
    try {
      final trips = await _tripService.getMyTrips();
      final active = trips.where((trip) {
        final status = trip['status']?.toString().toUpperCase() ?? '';
        return status == 'ACTIVE';
      }).toList();
      
      setState(() {
        activeTrips = active.cast<Map<String, dynamic>>();
      });
      
      _checkActiveTripsDistance();
    } catch (e) {
      debugPrint('Error loading active trips: $e');
    }
  }

  Future<void> _checkActiveTripsDistance() async {
    if (currentPosition == null || activeTrips.isEmpty) return;

    final Map<int, bool> canEndMap = {};
    final Map<int, double?> distanceMap = {};

    for (final trip in activeTrips) {
      final tripId = trip['id'] as int;
      final points = trip['points'] as List<dynamic>? ?? [];
      
      // Find END point (arrival)
      Map<String, dynamic>? arrivalPoint;
      for (final point in points) {
        if (point['pointType']?.toString().toUpperCase() == 'END') {
          arrivalPoint = point as Map<String, dynamic>;
          break;
        }
      }

      if (arrivalPoint != null && 
          arrivalPoint['latitude'] != null && 
          arrivalPoint['longitude'] != null) {
        final arrivalLat = (arrivalPoint['latitude'] as num).toDouble();
        final arrivalLon = (arrivalPoint['longitude'] as num).toDouble();
        
        final distance = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          arrivalLat,
          arrivalLon,
        );
        
        distanceMap[tripId] = distance;
        canEndMap[tripId] = distance <= 20000.0; // 20km radius
      }
    }

    setState(() {
      tripDistanceMap = distanceMap;
      tripCanEndMap = canEndMap;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load real dashboard data
      final dashboardOverview = await _dashboardService.getDashboardOverview();
      
      if (dashboardOverview != null) {
        if (mounted) {
          setState(() {
            dashboardData = dashboardOverview;
            isLoading = false;
          });
        }
      } else {
        // Fallback: load individual components
        await _loadFallbackDashboardData();
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      await _loadFallbackDashboardData();
    }
  }

  Future<void> _loadFallbackDashboardData() async {
    try {
      // Load individual dashboard components
      final stats = await _dashboardService.getDashboardStats();
      final recentTrips = await _dashboardService.getRecentTrips();
      
      // Try to get upcoming trips from dashboard service, fallback to trip service
      List<dynamic> upcomingTrips = await _dashboardService.getUpcomingTrips();
      if (upcomingTrips.isEmpty) {
        // Fallback: get driver's trips and filter for upcoming ones
        try {
          final allTrips = await _tripService.getMyTrips();
          final now = DateTime.now();
          upcomingTrips = allTrips.where((trip) {
            try {
              final departureTime = DateTime.parse(trip['departureTime'] as String? ?? '');
              return departureTime.isAfter(now);
            } catch (e) {
              return false;
            }
          }).toList();
          print('DEBUG: Loaded ${upcomingTrips.length} upcoming trips from TripService');
        } catch (e) {
          print('DEBUG: Error loading upcoming trips from TripService: $e');
          upcomingTrips = [];
        }
      }
      
      final earnings = await _dashboardService.getEarningsSummary();
      
      final fallbackData = {
        'stats': stats ?? {
          'totalTrips': 0,
          'completedTrips': 0,
          'upcomingTrips': 0,
          'totalEarnings': 0.0,
          'rating': 0.0,
        },
        'recentTrips': recentTrips,
        'upcomingTrips': upcomingTrips,
        'earnings': earnings,
      };
      
      if (mounted) {
        setState(() {
          dashboardData = fallbackData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isPassenger = roleString.contains('PASS');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDashboardData();
              _loadActiveTrips();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildDashboardContent(),
      floatingActionButton: !isPassenger
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TripCreationWizard()),
                );
                if (result != null) {
                  _loadDashboardData();
                  // If we received the created trip payload, open My Trips
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyTripsScreen()),
                  );
                  _loadDashboardData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (dashboardData == null) return const SizedBox();

    final stats = dashboardData!['stats'] as Map<String, dynamic>?;
    final recentTrips = dashboardData!['recentTrips'] as List<dynamic>? ?? [];
    final upcomingTrips = dashboardData!['upcomingTrips'] as List<dynamic>? ?? [];
    final earnings = dashboardData!['earnings'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          if (stats != null) _buildStatsSection(stats) else _buildEmptyState('No stats available yet'),
          const SizedBox(height: 20),
          if (activeTrips.isNotEmpty) _buildActiveTripsSection(activeTrips) else _buildSectionHeaderWithEmpty('Active Trips', 'No active trips'),
          const SizedBox(height: 20),
          if (upcomingTrips.isNotEmpty) _buildUpcomingTripsSection(upcomingTrips) else _buildSectionHeaderWithEmpty('Upcoming Trips', 'No upcoming trips'),
          const SizedBox(height: 20),
          if (recentTrips.isNotEmpty) _buildRecentTripsSection(recentTrips) else _buildSectionHeaderWithEmpty('Recent Trips', 'No recent trips'),
          const SizedBox(height: 20),
          if (earnings != null) _buildEarningsSection(earnings),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = context.watch<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isDriver = roleString.contains('DRIVER') || roleString.contains('CONDUCT');
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your carpooling overview',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons row
          Row(
            children: [
              if (isDriver)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyTripsScreen()),
                      );
                      _loadDashboardData();
                    },
                    icon: const Icon(Icons.directions_car, size: 18),
                    label: const Text('My Trips'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                    );
                    // Refresh dashboard when returning from My Bookings
                    _loadDashboardData();
                  },
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Bookings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final user = context.watch<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isDriver = roleString.contains('DRIVER') || roleString.contains('CONDUCT');

    final totalTrips = (stats['totalTrips'] as num?)?.toInt() ?? 0;
    final averageRating = (stats['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalPassengers = (stats['totalPassengers'] as num?)?.toInt() ?? 0;
    final completedTrips = (stats['completedTrips'] as num?)?.toInt() ?? 0;
    final upcomingTrips = (stats['upcomingTrips'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
          const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Taller cards to avoid clipped text on small screens
          childAspectRatio: 1.0,
          children: [
            _buildStatCard('Total Trips', totalTrips.toString(), Icons.directions_car),
            _buildStatCard('Completed', completedTrips.toString(), Icons.check_circle),
            _buildStatCard('Upcoming', upcomingTrips.toString(), Icons.schedule),
            // Always show rating card
            _buildStatCard('Rating', averageRating.toStringAsFixed(1), Icons.star),
            // For drivers, also show passengers
            if (isDriver) _buildStatCard('Passengers', totalPassengers.toString(), Icons.people),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripsSection(List<Map<String, dynamic>> trips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Trips',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${trips.length}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...trips.map((trip) => _buildActiveTripCard(trip)),
      ],
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> trip) {
    final tripId = trip['id'] as int;
    final canEnd = tripCanEndMap[tripId] ?? false;
    final distance = tripDistanceMap[tripId];
    final departureCity = trip['departureCity'] as String? ?? 'Unknown';
    final arrivalCity = trip['arrivalCity'] as String? ?? 'Unknown';
    final departureTime = trip['departureTime'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$departureCity → $arrivalCity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Departure: ${_formatDateTime(departureTime)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Distance to arrival: ${(distance / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: canEnd ? Colors.green.shade700 : Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canEnd)
                ElevatedButton.icon(
                  onPressed: () => _endTripFromDashboard(trip),
                  icon: const Icon(Icons.flag, size: 18),
                  label: const Text('End Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                )
              else if (distance != null && distance > 20000)
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.location_on, size: 18),
                  label: Text('${(distance / 1000).toStringAsFixed(1)} km away'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _endTripFromDashboard(Map<String, dynamic> trip) async {
    final tripId = trip['id'] as int;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text('Are you sure you want to end this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Check if trip is ACTIVE
      final tripDetails = await _tripService.getTripDetails(tripId);
      final tripStatus = tripDetails['status']?.toString().toUpperCase();
      
      if (tripStatus != 'ACTIVE') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip is not active. Current status: $tripStatus'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadActiveTrips();
        return;
      }

      // Complete trip
      await _tripService.completeTrip(tripId);
      
      if (!mounted) return;

      // Notify via websocket
      if (!WebSocketService.instance.isConnected) {
        await WebSocketService.instance.connect();
      }
      WebSocketService.instance.sendMessage({
        'type': 'trip-completed',
        'tripId': tripId,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Get trip participants for rating
      final bookings = await _tripService.getTripBookings(tripId);
      final passengers = bookings
          .where((b) => b['status']?.toString().toUpperCase() == 'CONFIRMED')
          .map((b) => b['passenger'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .toList();

      // Prompt driver to rate passengers one by one
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _promptDriverRating(tripId, passengers);
        }
      });

      // Refresh data
      _loadActiveTrips();
      _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _promptDriverRating(int tripId, List<Map<String, dynamic>> passengers, {int currentIndex = 0}) {
    if (passengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ended. No passengers to rate.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Before opening the rating screen, skip passengers already rated for this trip
    () async {
      try {
        final api = ApiService.instance;
        final myRatings = await api.getUserRatings();
        // Filter out passengers already rated for this trip
        final List<Map<String, dynamic>> unrated = passengers.where((p) {
          final pid = (p['id'] ?? p['userId'] ?? p['passengerId']) as int?;
          if (pid == null) return true;
          return !(myRatings as List)
              .whereType<Map>()
              .any((r) => (r['voyageId'] == tripId) && (r['userId'] == pid));
        }).cast<Map<String, dynamic>>().toList();

        if (unrated.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All passengers already rated. Thank you!'),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }

        final idx = currentIndex.clamp(0, unrated.length - 1);
        final passenger = unrated[idx];

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RatingScreen(
              trip: {'id': tripId},
              userToRate: passenger,
              ratingType: 'passenger',
              onRatingComplete: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _promptDriverRating(tripId, unrated, currentIndex: idx + 1);
                  }
                });
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('Failed to filter already-rated passengers: $e');
        // Fallback to original behavior
        if (!mounted) return;
        final passenger = passengers[currentIndex];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RatingScreen(
              trip: {'id': tripId},
              userToRate: passenger,
              ratingType: 'passenger',
              onRatingComplete: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _promptDriverRating(tripId, passengers, currentIndex: currentIndex + 1);
                  }
                });
              },
            ),
          ),
        );
      }
    }();
  }

  Widget _buildUpcomingTripsSection(List<dynamic> trips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Trips',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...trips.take(3).map((trip) => _buildTripCard(trip, isUpcoming: true)),
      ],
    );
  }

  Widget _buildRecentTripsSection(List<dynamic> trips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Trips',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...trips.take(3).map((trip) => _buildTripCard(trip, isUpcoming: false)),
      ],
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, {required bool isUpcoming}) {
    final departureCity = trip['departureCity'] as String? ?? 'Unknown';
    final arrivalCity = trip['arrivalCity'] as String? ?? 'Unknown';
    final departureTime = trip['departureTime'] as String? ?? '';
    final price = (trip['price'] as num?)?.toDouble() ?? (trip['pricePerSeat'] as num?)?.toDouble() ?? 0.0;
    final status = trip['status'] as String? ?? '';

    final user = context.read<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isDriver = roleString.contains('DRIVER') || roleString.contains('CONDUCT');

    final int availableSeats = (trip['availableSeats'] as num?)?.toInt() ?? 0;
    final int maxSeats = (trip['maxSeats'] as num?)?.toInt() ?? 0;
    final int confirmedSeats = (maxSeats - availableSeats) < 0 ? 0 : (maxSeats - availableSeats);

    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUpcoming 
                ? colorScheme.primaryContainer 
                : colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isUpcoming ? Icons.schedule : Icons.check_circle,
              color: isUpcoming 
                ? colorScheme.primary 
                : colorScheme.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$departureCity → $arrivalCity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Departure: ${_formatDateTime(departureTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: !isDriver
                        ? Text(
                            '${price.toStringAsFixed(2)} TND',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Seats: $confirmedSeats / $maxSeats',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Available: $availableSeats',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection(Map<String, dynamic> earnings) {
    final totalEarnings = earnings['totalEarnings'] as double? ?? 0.0;
    final thisMonthEarnings = earnings['thisMonthEarnings'] as double? ?? 0.0;
    final totalTrips = earnings['totalTrips'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[600]!, Colors.green[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${totalEarnings.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${thisMonthEarnings.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Trips',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        totalTrips.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithEmpty(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildEmptyState(message),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
