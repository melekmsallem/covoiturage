import 'package:flutter/material.dart';
import 'flutter_payment_button.dart';
import 'flutter_payment_service.dart';

// Example of how to integrate payment functionality into booking lists
class BookingListExample extends StatefulWidget {
  const BookingListExample({Key? key}) : super(key: key);

  @override
  State<BookingListExample> createState() => _BookingListExampleState();
}

class _BookingListExampleState extends State<BookingListExample> {
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    // This would normally load from your API service
    // For demo purposes, using mock data
    setState(() {
      _bookings = [
        {
          'id': 1,
          'tripInfo': 'Tunis → Sfax',
          'driverName': 'Ahmed Ben Ali',
          'departureTime': '2024-01-15 10:00',
          'amount': 25.50,
          'status': 'CONFIRMED',
          'numberOfSeats': 2,
        },
        {
          'id': 2,
          'tripInfo': 'Sousse → Monastir',
          'driverName': 'Fatma Trabelsi',
          'departureTime': '2024-01-16 14:30',
          'amount': 15.00,
          'status': 'PENDING',
          'numberOfSeats': 1,
        },
        {
          'id': 3,
          'tripInfo': 'Bizerte → Tunis',
          'driverName': 'Mohamed Khelil',
          'departureTime': '2024-01-17 08:00',
          'amount': 18.75,
          'status': 'CONFIRMED',
          'numberOfSeats': 1,
        },
      ];
    });
  }

  Future<void> _onPaymentCompleted(int bookingId) async {
    // Refresh the booking list or update specific booking
    await _loadBookings();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['tripInfo'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driver: ${booking['driverName']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Departure: ${booking['departureTime']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Booking Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Booking Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seats: ${booking['numberOfSeats']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  PaymentService.formatAmount(booking['amount']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // Payment Button (only for confirmed bookings)
            if (booking['status'] == 'CONFIRMED') ...[
              const SizedBox(height: 12),
              PaymentButton(
                reservationId: booking['id'],
                amount: booking['amount'].toDouble(),
                tripInfo: booking['tripInfo'],
                driverName: booking['driverName'],
                bookingStatus: booking['status'],
                onPaymentCompleted: () => _onPaymentCompleted(booking['id']),
              ),
            ],

            // Action buttons for different statuses
            const SizedBox(height: 12),
            Row(
              children: [
                if (booking['status'] == 'PENDING') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle cancel booking
                        _showCancelDialog(booking);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
                if (booking['status'] == 'CONFIRMED') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle contact driver
                        _showContactDriverDialog(booking);
                      },
                      child: const Text('Contact Driver'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle view details
                        _showBookingDetails(booking);
                      },
                      child: const Text('Details'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel your booking for ${booking['tripInfo']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle cancellation logic
              _cancelBooking(booking['id']);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showContactDriverDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${booking['driverName']}'),
            const SizedBox(height: 8),
            const Text('You can contact the driver through:'),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('Call'),
              subtitle: Text('+216 XX XXX XXX'),
            ),
            const ListTile(
              leading: Icon(Icons.message),
              title: Text('Message'),
              subtitle: Text('Send in-app message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Trip', booking['tripInfo']),
            _buildDetailRow('Driver', booking['driverName']),
            _buildDetailRow('Departure', booking['departureTime']),
            _buildDetailRow('Seats', booking['numberOfSeats'].toString()),
            _buildDetailRow('Amount', PaymentService.formatAmount(booking['amount'])),
            _buildDetailRow('Status', booking['status']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(int bookingId) {
    // Handle booking cancellation logic
    setState(() {
      _bookings.removeWhere((booking) => booking['id'] == bookingId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking cancelled successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}








