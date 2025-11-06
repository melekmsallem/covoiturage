import 'package:flutter/material.dart';
import '../../services/trip_service.dart';
import '../../widgets/simple_location_picker_widget.dart';

class PassengerPickupScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> trip;

  const PassengerPickupScreen({
    super.key,
    required this.booking,
    required this.trip,
  });

  @override
  State<PassengerPickupScreen> createState() => _PassengerPickupScreenState();
}

class _PassengerPickupScreenState extends State<PassengerPickupScreen> {
  final _tripService = TripService();
  bool _isLoading = false;
  Map<String, dynamic>? _currentPickupPoint;

  @override
  void initState() {
    super.initState();
    _loadCurrentPickupPoint();
  }

  void _loadCurrentPickupPoint() {
    if (widget.booking['passengerPickupAddress'] != null) {
      setState(() {
        _currentPickupPoint = {
          'address': widget.booking['passengerPickupAddress'],
          'latitude': widget.booking['passengerPickupLatitude'],
          'longitude': widget.booking['passengerPickupLongitude'],
        };
      });
    }
  }

  Future<void> _selectPickupPoint() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleLocationPickerWidget(
          title: 'Select Your Pickup Point',
          onLocationSelected: _savePickupPoint,
          initialLocation: _currentPickupPoint,
          cityInfo: {
            'name': widget.trip['departureCity'],
            'latitude': widget.trip['departureCityLatitude'],
            'longitude': widget.trip['departureCityLongitude'],
          },
          restrictToCity: true,
        ),
      ),
    );
  }

  Future<void> _savePickupPoint(Map<String, dynamic> location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _tripService.setPickupPoint(
        bookingId: widget.booking['id'],
        address: location['address'],
        latitude: location['latitude'],
        longitude: location['longitude'],
      );

      setState(() {
        _currentPickupPoint = location;
      });

      if (mounted) {
        // Pickup point set successfully
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set pickup point: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Pickup Point'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('From: ${widget.trip['departureCity']}'),
                    Text('To: ${widget.trip['arrivalCity']}'),
                    Text('Date: ${_formatDateTime(widget.trip['departureTime'])}'),
                    Text('Pickup Mode: ${widget.trip['pickupMode'] == 'INDIVIDUAL_PICKUP' ? 'Individual Pickup' : 'Designated Points'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup Point Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Since this is an individual pickup trip, you need to set your pickup point within ${widget.trip['departureCity']}. The driver will pick you up from this location.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current Pickup Point
            if (_currentPickupPoint != null) ...[
              Text(
                'Current Pickup Point',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentPickupPoint!['address'],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_currentPickupPoint!['latitude'].toStringAsFixed(6)}, Lng: ${_currentPickupPoint!['longitude'].toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _selectPickupPoint,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on),
                    label: Text(_currentPickupPoint != null ? 'Update Pickup Point' : 'Set Pickup Point'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure to select a location that is easily accessible and where the driver can safely pick you up.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}



