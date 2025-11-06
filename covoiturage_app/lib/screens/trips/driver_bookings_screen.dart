import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/trip_service.dart';
import '../../widgets/report_dialog.dart';
import '../chat/chat_screen.dart';
import '../chat/group_chat_screen.dart';

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
        final tripId = (trip['id'] as num?)?.toInt() ?? 0;
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
      _showBeautifulSuccessDialog(
        title: 'Booking Accepted! 🎉',
        message: 'You have successfully accepted this booking. The passenger has been notified.',
        icon: Icons.check_circle,
        color: Colors.green,
      );
      _loadDriverData(); // Refresh the data
    } catch (e) {
      _showErrorSnackBar('Failed to accept booking: $e');
    }
  }

  Future<void> _rejectBooking(int bookingId) async {
    try {
      await _tripService.cancelBooking(bookingId);
      _showBeautifulSuccessDialog(
        title: 'Booking Rejected',
        message: 'You have rejected this booking. The passenger has been notified and their coins have been refunded.',
        icon: Icons.cancel,
        color: Colors.orange,
      );
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

  void _showReportDialog(Map<String, dynamic> booking, Map<String, dynamic>? passenger, Map<String, dynamic> trip) {
    if (passenger == null) {
      _showErrorSnackBar('Passenger information not available');
      return;
    }
    
    final bookingId = (booking['id'] as num?)?.toInt();
    final tripId = (trip['id'] as num?)?.toInt();
    
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUser: passenger,
        bookingId: bookingId,
        tripId: tripId,
        userRole: 'passenger',
      ),
    ).then((success) {
      if (success == true) {
        // Refresh bookings if report was successful
        _loadDriverData();
      }
    });
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


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showBeautifulSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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
                          final tripId = (trip['id'] as num?)?.toInt() ?? 0;
                          final bookings = _tripBookings[tripId] ?? [];
                          return _buildTripCard(trip, bookings);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, List<dynamic> bookings) {
    final departureTime = DateTime.parse(trip['departureTime']);
    final price = (trip['pricePerSeat'] as num?)?.toDouble() ?? 0.0;
    final availableSeats = (trip['availableSeats'] as num?)?.toInt() ?? 0;
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
                      '${price.toInt()} coins',
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

            // Pickup mode information
            const SizedBox(height: 12),
            _buildPickupModeInfo(trip),

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
        ? '${passenger['firstName'] ?? ''} ${passenger['lastName'] ?? ''}'.trim()
        : 'Unknown Passenger';
    final passengerRating = (passenger?['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Extract pickup point information (for INDIVIDUAL_PICKUP trips)
    final trip = booking['trip'] as Map<String, dynamic>? ?? {};
    final tripPickupMode = trip['pickupMode'] as String?;
    final passengerPickupAddress = booking['passengerPickupAddress'] as String?;
    final passengerPickupLatitude = booking['passengerPickupLatitude'] as double?;
    final passengerPickupLongitude = booking['passengerPickupLongitude'] as double?;

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
                    Row(
                      children: [
                        Text(
                          '$numberOfSeats seat${numberOfSeats > 1 ? 's' : ''} • ${totalPrice.toInt()} coins',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (passengerRating > 0) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            passengerRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
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
          
          // Pickup Point (for INDIVIDUAL_PICKUP trips)
          if (tripPickupMode == 'INDIVIDUAL_PICKUP' && passengerPickupAddress != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passengerPickupAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                        if (passengerPickupLatitude != null && passengerPickupLongitude != null)
                          Text(
                            'Lat: ${passengerPickupLatitude.toStringAsFixed(6)}, Lng: ${passengerPickupLongitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Report button (for all statuses except cancelled)
          if (status.toUpperCase() != 'CANCELLED') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showReportDialog(booking, passenger, trip),
                  icon: Icon(Icons.flag, size: 16, color: Colors.red[600]),
                  label: Text(
                    'Report',
                    style: TextStyle(color: Colors.red[600], fontSize: 12),
                  ),
                ),
              ],
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
          
          // Chat and contact buttons for confirmed bookings
          if (status.toUpperCase() == 'CONFIRMED') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChatScreen(booking),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openGroupChatScreen(booking),
                    icon: const Icon(Icons.group, size: 16),
                    label: const Text('Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPassenger(booking),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildPickupModeInfo(Map<String, dynamic> trip) {
    final pickupMode = trip['pickupMode'] as String?;
    final pickupPoints = trip['pickupPoints'] as List<dynamic>? ?? [];
    
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup Mode: ${pickupMode == 'DESIGNATED_POINT' ? 'Designated Points' : 'Individual Pickup'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pickupMode == 'DESIGNATED_POINT' ? Colors.blue.shade700 : Colors.green.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
          if (pickupMode == 'DESIGNATED_POINT' && pickupPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Designated pickup points:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...pickupPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        point['address'] ?? 'Pickup point',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else if (pickupMode == 'INDIVIDUAL_PICKUP') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Passengers will share their location with you',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pickup details will be provided',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  void _openChatScreen(Map<String, dynamic> booking) {
    final passenger = booking['passenger'] as Map<String, dynamic>? ?? {};
    
    // Find the trip associated with this booking
    Map<String, dynamic>? trip;
    for (var t in _myTrips) {
      final tripId = (t['id'] as num?)?.toInt() ?? 0;
      final bookings = _tripBookings[tripId] ?? [];
      if (bookings.any((b) => b['id'] == booking['id'])) {
        trip = t;
        break;
      }
    }
    
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip information not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          booking: booking,
          trip: trip!,
          otherUser: passenger,
        ),
      ),
    );
  }

  void _openGroupChatScreen(Map<String, dynamic> booking) {
    // Find the trip associated with this booking
    Map<String, dynamic>? trip;
    for (var t in _myTrips) {
      final tripId = (t['id'] as num?)?.toInt() ?? 0;
      final bookings = _tripBookings[tripId] ?? [];
      if (bookings.any((b) => b['id'] == booking['id'])) {
        trip = t;
        break;
      }
    }
    
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip information not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get current user info from AuthProvider or pass a simple user object
    final currentUser = {
      'id': 20, // This should be dynamically retrieved from AuthProvider
      'firstName': 'Current',
      'lastName': 'User',
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          trip: trip!,
          currentUser: currentUser,
        ),
      ),
    );
  }

  Future<void> _callPassenger(Map<String, dynamic> booking) async {
    final passenger = booking['passenger'] as Map<String, dynamic>? ?? {};
    final phoneNumber = passenger['phoneNumber'] as String?;
    final passengerName = '${passenger['firstName']} ${passenger['lastName']}';
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passenger phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create tel: URL
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
      
      // Check if device can make phone calls
      if (await canLaunchUrl(phoneUri)) {
        // Launch phone app directly
        await launchUrl(phoneUri);
      } else {
        // Fallback: show dialog with copy option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Call Passenger'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Passenger: $passengerName'),
                const SizedBox(height: 8),
                Text('Phone: $phoneNumber'),
                const SizedBox(height: 16),
                const Text(
                  'Unable to launch phone app. You can copy this number and call manually.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: phoneNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Copy Number'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
