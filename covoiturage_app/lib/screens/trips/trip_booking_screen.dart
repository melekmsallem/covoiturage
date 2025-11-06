import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/trip_service.dart';
import '../../services/coin_service.dart';
import '../../widgets/coin_balance_widget.dart';
import '../../widgets/simple_location_picker_widget.dart';

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
  Map<String, dynamic>? _selectedPickupPoint;
  double _coinBalance = 0.0;
  bool _isCheckingBalance = false;

  @override
  void initState() {
    super.initState();
    _checkCoinBalance();
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkCoinBalance() async {
    setState(() {
      _isCheckingBalance = true;
    });

    try {
      final balanceData = await CoinService.getBalance();
      setState(() {
        _coinBalance = (balanceData['balance'] ?? 0.0).toDouble();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load coin balance: $e')),
        );
      }
    } finally {
      setState(() {
        _isCheckingBalance = false;
      });
    }
  }

  Future<void> _selectPickupPoint() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleLocationPickerWidget(
          title: 'Select Your Pickup Point',
          onLocationSelected: (location) {
            setState(() {
              _selectedPickupPoint = location;
            });
          },
          initialLocation: _selectedPickupPoint,
          cityInfo: widget.trip['departureCityInfo'],
          restrictToCity: true,
        ),
      ),
    );
  }

  Future<void> _bookTrip() async {
    if (!_validateForm()) return;

    // Check coin balance
    final totalPrice = widget.trip['pricePerSeat'] * _selectedSeats;
    if (_coinBalance < totalPrice) {
      _showInsufficientBalanceDialog(totalPrice);
      return;
    }

    // Validate pickup point for individual pickup trips
    if (widget.trip['pickupMode'] == 'INDIVIDUAL_PICKUP' && _selectedPickupPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your pickup point'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingRequest = _tripService.formatBookingRequest(
        numberOfSeats: _selectedSeats,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        pickupPoint: _selectedPickupPoint,
      );

      final response = await _tripService.bookTrip(widget.trip['id'], bookingRequest);
      
      if (mounted) {
        _showBeautifulBookingSuccessDialog(response);
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

  void _showInsufficientBalanceDialog(double requiredAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Coin Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need ${requiredAmount.toStringAsFixed(2)} coins to book this trip.'),
            const SizedBox(height: 8),
            Text('Current balance: ${_coinBalance.toStringAsFixed(2)} coins'),
            const SizedBox(height: 16),
            const Text('Would you like to purchase more coins?'),
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
              Navigator.pushNamed(context, '/coin-purchase');
            },
            child: const Text('Buy Coins'),
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

  void _showBeautifulBookingSuccessDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Successful! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your booking has been confirmed!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBookingInfoRow('Trip', '${widget.trip['departureCity']} → ${widget.trip['arrivalCity']}'),
                    const SizedBox(height: 8),
                    _buildBookingInfoRow('Seats', '$_selectedSeats'),
                    const SizedBox(height: 8),
                    _buildBookingInfoRow('Total', '${(widget.trip['pricePerSeat'] * _selectedSeats).toInt()} coins'),
                    const SizedBox(height: 8),
                    _buildBookingInfoRow('Status', '${booking['status']}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'The driver will be notified and can confirm your booking.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(booking); // Return to previous screen with booking data
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final price = (trip['pricePerSeat'] as num?)?.toDouble() ?? 0.0;
    final availableSeats = (trip['availableSeats'] as num?)?.toInt() ?? 0;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trip Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_isCheckingBalance)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          CoinBalanceWidget(
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                      ],
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
                              '${price.toInt()} coins',
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

                    // Pickup point selection for individual pickup trips
                    if (trip['pickupMode'] == 'INDIVIDUAL_PICKUP') ...[
                      const Text(
                        'Pickup Point',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.blue),
                          title: Text(
                            _selectedPickupPoint?['address'] ?? 'Select your pickup point',
                            style: TextStyle(
                              color: _selectedPickupPoint != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: _selectedPickupPoint != null 
                            ? Text('Lat: ${_selectedPickupPoint!['latitude']?.toStringAsFixed(4)}, Lng: ${_selectedPickupPoint!['longitude']?.toStringAsFixed(4)}')
                            : const Text('Tap to select your pickup location'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _selectPickupPoint,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                              Text('$_selectedSeats seat${_selectedSeats > 1 ? 's' : ''} × ${price.toInt()} coins'),
                              Text('${(price * _selectedSeats).toInt()} coins'),
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
                                '${totalPrice.toInt()} coins',
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
                        'Book Trip - ${totalPrice.toInt()} coins',
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









