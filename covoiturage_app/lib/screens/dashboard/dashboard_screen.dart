import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../trips/create_trip_screen.dart';
import '../trips/my_trips_screen.dart';
import '../trips/my_bookings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final overview = await _dashboardService.getDashboardOverview();
      if (overview != null) {
        setState(() {
          dashboardData = overview;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load dashboard data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isPassenger = roleString.contains('PASS');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
                  MaterialPageRoute(builder: (context) => const CreateTripScreen()),
                );
                if (result != null) {
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
    // Treat DRIVER or French CONDUCTEUR/CONDUCT as driver
    final bool isDriver = roleString.contains('DRIVER') || roleString.contains('CONDUCT');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your carpooling overview',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
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
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Trips', totalTrips.toString(), Icons.directions_car),
            _buildStatCard('Completed', completedTrips.toString(), Icons.check_circle),
            _buildStatCard('Upcoming', upcomingTrips.toString(), Icons.schedule),
            if (isDriver)
              _buildStatCard('Passengers', totalPassengers.toString(), Icons.people)
            else
              _buildStatCard('Rating', averageRating.toStringAsFixed(1), Icons.star),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue[600], size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
    final price = trip['price'] as double? ?? (trip['pricePerSeat'] as num?)?.toDouble() ?? 0.0;
    final status = trip['status'] as String? ?? '';

    final user = context.read<AuthProvider>().user;
    final String roleString = (user?['role'] ?? '').toString().toUpperCase();
    final bool isDriver = roleString.contains('DRIVER') || roleString.contains('CONDUCT');

    final int availableSeats = (trip['availableSeats'] as num?)?.toInt() ?? 0;
    final int maxSeats = (trip['maxSeats'] as num?)?.toInt() ?? 0;
    final int confirmedSeats = (maxSeats - availableSeats) < 0 ? 0 : (maxSeats - availableSeats);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUpcoming ? Colors.blue[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              isUpcoming ? Icons.schedule : Icons.check,
              color: isUpcoming ? Colors.blue[600] : Colors.green[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$departureCity → $arrivalCity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Departure: ${_formatDateTime(departureTime)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isDriver)
                      Text(
                        '${price.toStringAsFixed(2)} TND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seats: $confirmedSeats / $maxSeats confirmed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Available: $availableSeats',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
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
