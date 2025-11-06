import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/trip_service.dart';
import '../../services/api_service.dart';
import 'trip_bookings_screen.dart';
import 'edit_trip_screen.dart';
import 'trip_start_reminder_screen.dart';
import 'realtime_tracking_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final TripService _tripService = TripService();
  final ApiService _apiService = ApiService.instance;
  
  List<dynamic> trips = [];
  bool isLoading = true;
  String? errorMessage;
  Set<int> _tripsWithAllPassengersRated = {}; // Track trips where all passengers are rated

  @override
  void initState() {
    super.initState();
    _loadMyTrips();
  }

  Future<void> _loadMyTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final myTrips = await _tripService.getMyTrips();
      print('DEBUG: Total trips received: ${myTrips.length}');
      
      // Filter to show only future trips
      final now = DateTime.now();
      print('DEBUG: Current time: $now');
      
      // Temporarily show all trips for testing
      print('DEBUG: Showing all trips for testing (${myTrips.length} total)');
      
      setState(() {
        trips = myTrips; // Show all trips temporarily
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyTrips,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildTripsList(),
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
            onPressed: _loadMyTrips,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No trips created yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first trip to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final id = trip['id'] as int? ?? 0;
    // Try multiple sources for route labels: direct fields, cities array, GPS points
    final route = _extractRoute(trip);
    final departureCity = route.$1;
    final arrivalCity = route.$2;
    final departureTime = trip['departureTime'] as String? ?? '';
    final arrivalTime = trip['arrivalTime'] as String? ?? '';
    final price = trip['pricePerSeat'] as double? ?? 0.0;
    final status = trip['status'] as String? ?? '';
    final availableSeats = trip['availableSeats'] as int? ?? 0;
    final maxSeats = trip['maxSeats'] as int? ?? 0;
    final description = trip['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$departureCity → $arrivalCity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Trip details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$departureCity → $arrivalCity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Times
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Departure: ${_formatDateTime(departureTime)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Arrival: ${_formatDateTime(arrivalTime)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Price and seats
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.payments, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${price.toStringAsFixed(2)} coins per seat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.people, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '$availableSeats/$maxSeats seats',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rating button for completed trips (only if not all passengers rated)
                if (status == 'COMPLETED' && !_tripsWithAllPassengersRated.contains(id))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final tripService = TripService();
                          final tripId = (trip['id'] as num?)?.toInt();
                          if (tripId == null) return;

                          final fullTripDetails = await tripService.getTripDetails(tripId);
                          print('DEBUG: Full trip details loaded for rating: ${fullTripDetails['passengers']?.length ?? 0} passengers');

                          // Get passengers from the trip
                          final passengers = (fullTripDetails['passengers'] as List<dynamic>?) ?? [];
                          final reservations = (fullTripDetails['reservations'] as List<dynamic>?) ?? [];

                          final List<Map<String, dynamic>> passengerCandidates = [];
                          for (final p in passengers) {
                            if (p is Map) passengerCandidates.add(Map<String, dynamic>.from(p));
                          }
                          for (final r in reservations) {
                            if (r is Map && r['passenger'] is Map) {
                              passengerCandidates.add(Map<String, dynamic>.from(r['passenger']));
                            } else if (r is Map && r['passengerId'] != null) {
                              passengerCandidates.add({'id': r['passengerId']});
                            }
                          }

                          // Remove duplicates based on passenger ID
                          final Map<dynamic, Map<String, dynamic>> uniquePassengers = {};
                          for (final p in passengerCandidates) {
                            final pid = p['id'] ?? p['userId'] ?? p['passengerId'];
                            if (pid != null && !uniquePassengers.containsKey(pid)) {
                              uniquePassengers[pid] = p;
                            }
                          }

                          if (uniquePassengers.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aucun passager trouvé pour ce voyage.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          // Check which passengers have already been rated
                          try {
                            // getUserRatings returns List<dynamic> directly
                            final ratingsList = await _apiService.getUserRatings();

                            // Filter out already-rated passengers
                            final unratedPassengers = uniquePassengers.values.where((passenger) {
                              final passengerId = passenger['id'] ?? passenger['userId'] ?? passenger['passengerId'];
                              if (passengerId == null) return true; // Include if ID is missing
                              
                              // Check if this passenger has been rated for this trip
                              return !ratingsList.any((rating) {
                                if (rating is! Map<String, dynamic>) return false;
                                final ratingTripId = rating['voyageId'] ?? rating['tripId'];
                                final ratingUserId = rating['userId'];
                                
                                // Compare IDs (handle both int and String)
                                final ratingTripIdInt = ratingTripId is int 
                                    ? ratingTripId 
                                    : (ratingTripId is num ? ratingTripId.toInt() : int.tryParse(ratingTripId.toString()));
                                final ratingUserIdInt = ratingUserId is int 
                                    ? ratingUserId 
                                    : (ratingUserId is num ? ratingUserId.toInt() : int.tryParse(ratingUserId.toString()));
                                final passengerIdInt = passengerId is int 
                                    ? passengerId 
                                    : (passengerId is num ? passengerId.toInt() : int.tryParse(passengerId.toString()));
                                
                                return ratingTripIdInt == tripId && ratingUserIdInt == passengerIdInt;
                              });
                            }).toList();

                            if (unratedPassengers.isEmpty) {
                              // All passengers already rated
                              _tripsWithAllPassengersRated.add(tripId);
                              if (mounted) {
                                setState(() {});
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tous les passagers ont déjà été notés pour ce voyage.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              return;
                            }

                            // Show rating screen for first unrated passenger
                            final passengerToRate = unratedPassengers.first;
                            if (!mounted) return;
                            final result = await Navigator.pushNamed(
                              context,
                              '/rating',
                              arguments: {
                                'trip': Map<String, dynamic>.from(fullTripDetails),
                                'userToRate': passengerToRate,
                                'ratingType': 'passenger',
                              },
                            );

                            // If rating was submitted successfully, refresh to check if more passengers need rating
                            if (result == true && mounted) {
                              setState(() {
                                // Trigger rebuild to check if button should still be shown
                              });
                            }
                          } catch (e) {
                            print('Error checking ratings: $e');
                            // If check fails, allow rating attempt (backend will handle duplicate)
                            final passengerToRate = uniquePassengers.values.first;
                            if (!mounted) return;
                            Navigator.pushNamed(
                              context,
                              '/rating',
                              arguments: {
                                'trip': Map<String, dynamic>.from(fullTripDetails),
                                'userToRate': passengerToRate,
                                'ratingType': 'passenger',
                              },
                            );
                          }
                        } catch (e) {
                          print('Error navigating to rating: $e');
                        }
                      },
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Noter les passagers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                // Message if all passengers already rated
                if (status == 'COMPLETED' && _tripsWithAllPassengersRated.contains(id))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tous les passagers ont été notés',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                // Pickup mode information
                const SizedBox(height: 12),
                _buildPickupModeInfo(trip),
                
                const SizedBox(height: 16),
                
                // Action buttons
                if (status == 'PLANNED' && _shouldShowStartButton(trip))
                  // Show Start Trip and Track buttons for upcoming trips
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startTrip(id),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Start Trip & View Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _viewBookings(id),
                              icon: const Icon(Icons.list_alt, size: 18),
                              label: const Text('Bookings'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _startTracking(trip),
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text('Track'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[600],
                                side: BorderSide(color: Colors.orange[600]!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (status == 'IN_PROGRESS' || status == 'ACTIVE')
                  // Show only Track button for ongoing trips
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startTracking(trip),
                          icon: const Icon(Icons.my_location, size: 20),
                          label: const Text('Live Tracking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _viewBookings(id),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('View Bookings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                            side: BorderSide(color: Colors.blue[600]!),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Default buttons for other statuses
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewBookings(id),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('View Bookings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                            side: BorderSide(color: Colors.blue[600]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editTrip(trip),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
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

  // Extract route labels from trip
  // Returns Tuple(departure, arrival)
  (String, String) _extractRoute(Map<String, dynamic> trip) {
    String dep = (trip['departureCity'] as String?)?.trim() ?? '';
    String arr = (trip['arrivalCity'] as String?)?.trim() ?? '';

    if (dep.isEmpty || arr.isEmpty) {
      // Try 'cities' array [{name: ...}, ...]
      final cities = trip['cities'] as List<dynamic>?;
      if (cities != null && cities.isNotEmpty) {
        final first = cities.first as Map<String, dynamic>;
        final last = cities.length > 1 ? cities.last as Map<String, dynamic> : first;
        dep = dep.isNotEmpty ? dep : (first['name'] as String? ?? '').trim();
        arr = arr.isNotEmpty ? arr : (last['name'] as String? ?? '').trim();
      }
    }

    if (dep.isEmpty || arr.isEmpty) {
      // Try 'points' array with pointType START/END and 'address'
      final points = trip['points'] as List<dynamic>?;
      if (points != null && points.isNotEmpty) {
        Map<String, dynamic>? start;
        Map<String, dynamic>? end;
        for (final p in points) {
          final mp = p as Map<String, dynamic>;
          final type = (mp['pointType'] as String? ?? '').toUpperCase();
          if (type == 'START' && start == null) start = mp;
          if (type == 'END' && end == null) end = mp;
        }
        dep = dep.isNotEmpty ? dep : ((start?['address'] as String?)?.trim() ?? '');
        arr = arr.isNotEmpty ? arr : ((end?['address'] as String?)?.trim() ?? '');
      }
    }

    if (dep.isEmpty) dep = 'Unknown';
    if (arr.isEmpty) arr = 'Unknown';
    return (dep, arr);
  }

  void _viewBookings(int tripId) {
    final trip = trips.firstWhere((t) => t['id'] == tripId);
    final departureCity = trip['departureCity'] as String? ?? 'Unknown';
    final arrivalCity = trip['arrivalCity'] as String? ?? 'Unknown';
    final tripTitle = '$departureCity → $arrivalCity';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripBookingsScreen(
          tripId: tripId,
          tripTitle: tripTitle,
        ),
      ),
    );
  }

  void _editTrip(Map<String, dynamic> trip) {
    final id = trip['id'] as int? ?? 0;
    final departureCity = trip['departureCity'] as String? ?? 'Unknown';
    final arrivalCity = trip['arrivalCity'] as String? ?? 'Unknown';
    final tripTitle = '$departureCity → $arrivalCity';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(
          tripId: id,
          tripTitle: tripTitle,
        ),
      ),
    ).then((result) {
      // Refresh the trips list if the trip was updated
      if (result == true) {
        _loadMyTrips();
      }
    });
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildPickupModeInfo(Map<String, dynamic> trip) {
    final pickupMode = trip['pickupMode'] as String?;
    final pickupPoints = trip['pickupPoints'] as List<dynamic>? ?? [];
    
    // Debug logging
    print('DEBUG: Pickup mode for trip ${trip['id']}: $pickupMode');
    print('DEBUG: Full trip data: $trip');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pickupMode == 'DESIGNATED_POINT' ? Icons.location_on : Icons.my_location,
                color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue.shade600 : Colors.green.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Pickup: ${pickupMode == 'DESIGNATED_POINT' ? 'Designated Points' : 'Individual Pickup'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (pickupMode == 'DESIGNATED_POINT' && pickupPoints.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Pickup points:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...pickupPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 12,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        point['address'] ?? 'Pickup point',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else if (pickupMode == 'INDIVIDUAL_PICKUP') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Passengers share location',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
      case 'IN_PROGRESS':
      case 'ACTIVE':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  // Check if Start Trip button should be shown
  bool _shouldShowStartButton(Map<String, dynamic> trip) {
    try {
      final departureTimeStr = trip['departureTime'] as String?;
      if (departureTimeStr == null) return false;
      
      final departureTime = DateTime.parse(departureTimeStr);
      final now = DateTime.now();
      
      // Show if trip is within 2 hours (for testing, change to 1 hour for production)
      final diff = departureTime.difference(now);
      return diff.inMinutes <= 120 && diff.inMinutes >= -60;
    } catch (e) {
      return false;
    }
  }

  // Start trip - shows reminder with pickup points
  void _startTrip(int tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripStartReminderScreen(tripId: tripId),
      ),
    ).then((result) {
      // Refresh if trip was started
      if (result == true) {
        _loadMyTrips();
      }
    });
  }

  // Start real-time tracking
  Future<void> _startTracking(Map<String, dynamic> trip) async {
    final tripId = trip['id'] as int? ?? 0;
    
    // Show loading indicator
    if (!mounted) return;
    
    // Try to get participants from bookings if available
    final bookings = trip['bookings'] as List<dynamic>?;
    List<Map<String, dynamic>> participants = [];
    
    if (bookings != null && bookings.isNotEmpty) {
      participants = bookings
          .where((b) => b['status'] == 'CONFIRMED')
          .map((b) {
                // Handle both flattened and nested passenger data
                final passenger = b['passenger'] as Map<String, dynamic>?;
                return {
                  'id': passenger?['id'] ?? b['passengerId'],
                  'firstName': passenger?['firstName'] ?? b['passengerFirstName'] ?? 'Passenger',
                  'lastName': passenger?['lastName'] ?? b['passengerLastName'] ?? '',
                };
              })
          .toList();
    } else {
      // If no bookings in trip data, fetch them
      try {
        final fetchedBookings = await _tripService.getTripBookings(tripId);
        participants = fetchedBookings
            .where((b) => b['status'] == 'CONFIRMED')
            .map((b) {
                  // Handle both flattened and nested passenger data
                  final passenger = b['passenger'] as Map<String, dynamic>?;
                  return {
                    'id': passenger?['id'] ?? b['passengerId'],
                    'firstName': passenger?['firstName'] ?? b['passengerFirstName'] ?? 'Passenger',
                    'lastName': passenger?['lastName'] ?? b['passengerLastName'] ?? '',
                  };
                })
            .toList();
      } catch (e) {
        // If fetch fails, continue with empty participants
        print('Error fetching bookings for tracking: $e');
      }
    }
    
    print('DEBUG: Participants list: $participants');
    
    // Get pickup point(s) from GPS points OR passenger bookings
    Map<String, dynamic>? pickupPoint;
    List<Map<String, dynamic>> waypointList = [];
    final points = trip['points'] as List<dynamic>?;
    
    // For INDIVIDUAL_PICKUP trips, get pickup point from passenger bookings
    final pickupMode = trip['pickupMode'] as String?;
    if (pickupMode == 'INDIVIDUAL_PICKUP') {
      // Try to get pickup point from bookings
      final bookings = trip['bookings'] as List<dynamic>?;
      if (bookings != null && bookings.isNotEmpty) {
        // Get first confirmed booking with pickup coordinates
        final firstBooking = bookings.firstWhere(
          (b) => b['status'] == 'CONFIRMED' && 
                 b['passengerPickupLatitude'] != null && 
                 b['passengerPickupLongitude'] != null,
          orElse: () => null,
        );
        
        if (firstBooking != null) {
          pickupPoint = {
            'latitude': firstBooking['passengerPickupLatitude'] as double,
            'longitude': firstBooking['passengerPickupLongitude'] as double,
            'address': firstBooking['passengerPickupAddress'] as String? ?? 'Passenger Pickup',
          };
          print('DEBUG: Using pickup from booking: $pickupPoint');
          waypointList.add(pickupPoint);
        }
      }
      
      // If still no pickup point and bookings not in trip data, fetch them
      if (pickupPoint == null) {
        try {
          final fetchedBookings = await _tripService.getTripBookings(tripId);
          final firstBookingWithPickup = fetchedBookings.firstWhere(
            (b) => b['status'] == 'CONFIRMED' && 
                   b['passengerPickupLatitude'] != null && 
                   b['passengerPickupLongitude'] != null,
            orElse: () => null,
          );
          
          if (firstBookingWithPickup != null) {
            pickupPoint = {
              'latitude': firstBookingWithPickup['passengerPickupLatitude'] as double,
              'longitude': firstBookingWithPickup['passengerPickupLongitude'] as double,
              'address': firstBookingWithPickup['passengerPickupAddress'] as String? ?? 'Passenger Pickup',
            };
            print('DEBUG: Using pickup from fetched booking: $pickupPoint');
            waypointList.add(pickupPoint);
          }
        } catch (e) {
          print('Error fetching pickup from bookings: $e');
        }
      }
    } else if (trip['pickupMode'] == 'DESIGNATED_POINT') {
      // For designated pickup trips, include all pickup points in order
      final pickupPoints = trip['pickupPoints'] as List<dynamic>?;
      if (pickupPoints != null && pickupPoints.isNotEmpty) {
        for (final p in pickupPoints) {
          final lat = p['latitude'] as double?;
          final lon = p['longitude'] as double?;
          if (lat != null && lon != null) {
            waypointList.add({'latitude': lat, 'longitude': lon});
          }
        }
      }
    }
    
    // Fallback to trip GPS points if still no pickup point
    if (pickupPoint == null && points != null && points.isNotEmpty) {
      // Try to find a START or PICKUP point
      final startOrPickup = points.firstWhere(
        (p) => p['pointType'] == 'START' || p['pointType'] == 'PICKUP',
        orElse: () => points.first,
      );
      pickupPoint = {
        'latitude': startOrPickup['latitude'] as double? ?? 36.8065,
        'longitude': startOrPickup['longitude'] as double? ?? 10.1815,
        'address': startOrPickup['address'] as String? ?? 'Trip Start',
      };
      print('DEBUG: Using pickup from trip points: $pickupPoint');
      waypointList.add(pickupPoint);
    }
    
    // Add arrival point if available in points (prefer END or last)
    double? arrivalLat;
    double? arrivalLon;
    if (points != null && points.isNotEmpty) {
      final endPoint = points.lastWhere(
        (p) => p['pointType'] == 'END',
        orElse: () => points.last,
      );
      arrivalLat = endPoint['latitude'] as double?;
      arrivalLon = endPoint['longitude'] as double?;
      if (arrivalLat != null && arrivalLon != null) {
        waypointList.add({'latitude': arrivalLat, 'longitude': arrivalLon});
      }
    }

    // If arrival coordinates missing, try geocoding arrival city name
    if ((arrivalLat == null || arrivalLon == null)) {
      final cityName = (trip['arrivalCity'] as String?)?.trim();
      if (cityName != null && cityName.isNotEmpty) {
        try {
          final coords = await _geocodeCity(cityName);
          if (coords != null) {
            waypointList.add({'latitude': coords.$1, 'longitude': coords.$2});
          }
        } catch (e) {
          print('Geocoding failed for arrival city "$cityName": $e');
        }
      }
    }
    
    print('DEBUG: Final pickup point: $pickupPoint');
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealtimeTrackingScreen(
          tripId: tripId,
          userRole: 'DRIVER',
          participants: participants,
          pickupPoint: pickupPoint,
          waypoints: waypointList.isNotEmpty ? waypointList : null,
        ),
      ),
    );
  }

  // Simple city geocoding using Nominatim (OpenStreetMap)
  Future<(double, double)?> _geocodeCity(String city) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(city)}&format=json&limit=1');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'covoiturage_app/1.0 (contact@example.com)'
      }).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as List<dynamic>;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (_) {
      return null;
    }
  }
}