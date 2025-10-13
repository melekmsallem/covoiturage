import 'package:flutter/material.dart';
import '../../services/trip_service.dart';

class DriverBookingsScreen extends StatefulWidget {
  const DriverBookingsScreen({super.key});

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen> {
  final _tripService = TripService();
  List<dynamic> _myTrips = [];
  Map<int, List<dynamic>> _tripBookings = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load driver's trips
      final trips = await _tripService.getMyTrips();
      print('DEBUG: Loaded ${trips.length} trips for driver');
      for (var trip in trips) {
        print('DEBUG: Trip ID: ${trip['id']}, Driver: ${trip['driver']?['firstName']} ${trip['driver']?['lastName']}');
      }
      setState(() {
        _myTrips = trips;
      });

      // Load bookings for each trip
      for (var trip in trips) {
        final tripId = trip['id'] as int;
        try {
          final bookings = await _tripService.getTripBookings(tripId);
          print('DEBUG: Loaded ${bookings.length} bookings for trip $tripId');
          setState(() {
            _tripBookings[tripId] = bookings;
          });
        } catch (e) {
          print('Error loading bookings for trip $tripId: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptBooking(int bookingId) async {
    try {
      await _tripService.confirmBooking(bookingId);
      _showSuccessSnackBar('Booking accepted successfully');
      _loadDriverData(); // Refresh the data
    } catch (e) {
      _showErrorSnackBar('Failed to accept booking: $e');
    }
  }

  Future<void> _rejectBooking(int bookingId) async {
    try {
      await _tripService.cancelBooking(bookingId);
      _showSuccessSnackBar('Booking rejected successfully');
      _loadDriverData(); // Refresh the data
    } catch (e) {
      _showErrorSnackBar('Failed to reject booking: $e');
    }
  }

  void _showAcceptDialog(int bookingId, String passengerName, int seats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Booking'),
        content: Text('Accept booking from $passengerName for $seats seat${seats > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acceptBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(int bookingId, String passengerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Text('Reject booking from $passengerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.schedule;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trip Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading bookings',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDriverData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _myTrips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No trips created yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a trip to see bookings here',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDriverData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myTrips.length,
                        itemBuilder: (context, index) {
                          final trip = _myTrips[index];
                          final tripId = trip['id'] as int;
                          final bookings = _tripBookings[tripId] ?? [];
                          return _buildTripCard(trip, bookings);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, List<dynamic> bookings) {
    final departureTime = DateTime.parse(trip['departureTime']);
    final price = trip['pricePerSeat'] as double;
    final availableSeats = trip['availableSeats'] as int;
    final pendingBookings = bookings.where((b) => b['status'] == 'PENDING').toList();
    final confirmedBookings = bookings.where((b) => b['status'] == 'CONFIRMED').toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip['departureCity']} → ${trip['arrivalCity']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(departureTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toInt()} TND',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'per seat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trip stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Available',
                    availableSeats.toString(),
                    Icons.event_seat,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    pendingBookings.length.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Confirmed',
                    confirmedBookings.length.toString(),
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            // Bookings list
            if (bookings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...bookings.map((booking) => _buildBookingCard(booking)).toList(),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'No bookings yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? 'UNKNOWN';
    final numberOfSeats = booking['numberOfSeats'] as int? ?? 0;
    final totalPrice = booking['totalPrice'] as double? ?? 0.0;
    final reservationDate = booking['reservationDate'] as String?;
    final passenger = booking['passenger'] as Map<String, dynamic>?;
    final passengerName = passenger != null 
        ? '${passenger['firstName']} ${passenger['lastName']}'
        : 'Unknown Passenger';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  passengerName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$numberOfSeats seat${numberOfSeats > 1 ? 's' : ''} • ${totalPrice.toInt()} TND',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 12,
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (reservationDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Booked: ${_formatDateTime(DateTime.parse(reservationDate))}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],

          // Action buttons for pending bookings
          if (status.toUpperCase() == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(
                      booking['id'],
                      passengerName,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAcceptDialog(
                      booking['id'],
                      passengerName,
                      numberOfSeats,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
