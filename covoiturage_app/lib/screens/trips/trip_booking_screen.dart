import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/trip_service.dart';

class TripBookingScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripBookingScreen({super.key, required this.trip});

  @override
  State<TripBookingScreen> createState() => _TripBookingScreenState();
}

class _TripBookingScreenState extends State<TripBookingScreen> {
  final _tripService = TripService();
  final _seatsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  int _selectedSeats = 1;
  String? _seatsError;

  @override
  void dispose() {
    _seatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookTrip() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingRequest = _tripService.formatBookingRequest(
        numberOfSeats: _selectedSeats,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final response = await _tripService.bookTrip(widget.trip['id'], bookingRequest);
      
      if (mounted) {
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Booking failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    bool isValid = true;
    
    // Validate seats
    if (_selectedSeats < 1) {
      setState(() {
        _seatsError = 'Please select at least 1 seat';
      });
      isValid = false;
    } else if (_selectedSeats > widget.trip['availableSeats']) {
      setState(() {
        _seatsError = 'Not enough seats available';
      });
      isValid = false;
    } else {
      setState(() {
        _seatsError = null;
      });
    }

    return isValid;
  }

  void _showSuccessDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Booking Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your booking has been confirmed.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking ID: #${booking['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Seats: $_selectedSeats'),
                  Text('Total: ${(widget.trip['pricePerSeat'] * _selectedSeats).toInt()} TND'),
                  Text('Status: ${booking['status']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The driver will be notified and can confirm your booking.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to trip details
              Navigator.of(context).pop(); // Go back to search results
            },
            child: const Text('OK'),
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

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final price = trip['pricePerSeat'] as double;
    final availableSeats = trip['availableSeats'] as int;
    final totalPrice = price * _selectedSeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Trip'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip['departureCity']} → ${trip['arrivalCity']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDateTime(DateTime.parse(trip['departureTime']))}',
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
                                fontSize: 18,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Booking form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Number of seats
                    TextField(
                      controller: _seatsController,
                      decoration: InputDecoration(
                        labelText: 'Number of Seats',
                        prefixIcon: const Icon(Icons.people),
                        border: const OutlineInputBorder(),
                        errorText: _seatsError,
                        suffixText: 'of $availableSeats available',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        setState(() {
                          _selectedSeats = int.tryParse(value) ?? 1;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                        hintText: 'Any special requests or information for the driver',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),

                    const SizedBox(height: 16),

                    // Price breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$_selectedSeats seat${_selectedSeats > 1 ? 's' : ''} × ${price.toInt()} TND'),
                              Text('${(price * _selectedSeats).toInt()} TND'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${totalPrice.toInt()} TND',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Book Trip - ${totalPrice.toInt()} TND',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms and conditions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Your booking is pending driver confirmation\n'
                    '• You can cancel up to 2 hours before departure\n'
                    '• Payment will be processed after driver confirmation\n'
                    '• Contact the driver directly for any questions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}









