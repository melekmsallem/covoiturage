import 'package:flutter/material.dart';
import '../../services/trip_service.dart';
import 'trip_bookings_screen.dart';
import 'edit_trip_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final TripService _tripService = TripService();
  
  List<dynamic> trips = [];
  bool isLoading = true;
  String? errorMessage;

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
      setState(() {
        trips = myTrips;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip #$id',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${price.toStringAsFixed(2)} TND per seat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$availableSeats/$maxSeats seats',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rating button for completed trips
                if (status == 'COMPLETED')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/rating',
                          arguments: {
                            'trip': trip,
                            'userToRate': trip['passengers']?.isNotEmpty == true 
                                ? trip['passengers'][0] 
                                : {},
                            'ratingType': 'passenger',
                          },
                        );
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
                
                const SizedBox(height: 16),
                
                // Action buttons
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
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}