import 'package:flutter/material.dart';
import '../../../services/trip_creation_service.dart';
import '../../../services/trip_service.dart';
import '../../dashboard/dashboard_screen.dart';

class TripOptionsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onCreateTrip;

  const TripOptionsScreen({
    super.key,
    this.initialData,
    required this.onCreateTrip,
  });

  @override
  State<TripOptionsScreen> createState() => _TripOptionsScreenState();
}

class _TripOptionsScreenState extends State<TripOptionsScreen> {
  final _tripCreationService = TripCreationService();
  final _tripService = TripService();

  List<dynamic> _options = [];
  List<int> _selectedOptions = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      setState(() {
        _selectedOptions = List<int>.from(widget.initialData!['selectedOptions'] ?? []);
      });
    }
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    try {
      final formData = await _tripCreationService.getFormData();
      setState(() {
        _options = formData['options'] ?? [];
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load options: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTrip() async {
    if (_isSaving) return; // Prevent multiple submissions
    
    setState(() => _isSaving = true);
    try {
      // Create pickup points list - include departure point as first pickup point
      List<Map<String, dynamic>> finalPickupPoints = [];
      if (widget.initialData?['pickupMode'] == 'DESIGNATED_POINT') {
        // Add departure point as the first pickup point
        if (widget.initialData?['departurePoint'] != null) {
          finalPickupPoints.add({
            'address': widget.initialData!['departurePoint']['address'],
            'latitude': widget.initialData!['departurePoint']['latitude'],
            'longitude': widget.initialData!['departurePoint']['longitude'],
            'pickupTime': widget.initialData!['departureTime']?.toIso8601String(),
            'maxWaitingTime': 10, // 10 minutes default
            'pickupOrder': 1,
          });
        }
        // Add other designated pickup points
        final pickupPoints = widget.initialData?['pickupPoints'] as List<dynamic>? ?? [];
        for (int i = 0; i < pickupPoints.length; i++) {
          finalPickupPoints.add({
            'address': pickupPoints[i]['address'],
            'latitude': pickupPoints[i]['latitude'],
            'longitude': pickupPoints[i]['longitude'],
            'pickupTime': pickupPoints[i]['pickupTime'] ?? widget.initialData!['departureTime']?.toIso8601String(),
            'maxWaitingTime': pickupPoints[i]['maxWaitingTime'] ?? 10,
            'pickupOrder': i + 2, // Start from 2 since departure is 1
          });
        }
      }

      // Create real trip using API
      final tripData = {
        'departureCity': widget.initialData!['departureCity']['name'],
        'arrivalCity': widget.initialData!['arrivalCity']['name'],
        'departureTime': widget.initialData!['departureTime']?.toIso8601String(),
        'arrivalTime': widget.initialData!['arrivalTime']?.toIso8601String(),
        'pricePerSeat': widget.initialData!['price'],
        'maxSeats': widget.initialData!['maxSeats'],
        'description': widget.initialData!['description']?.isNotEmpty == true 
            ? widget.initialData!['description'] 
            : 'Carpool trip',
        'optionIds': _selectedOptions,
        'pickupMode': widget.initialData!['pickupMode'],
        'pickupPoints': widget.initialData!['pickupMode'] == 'DESIGNATED_POINT' ? finalPickupPoints : null,
        'allowLocationSharing': widget.initialData!['allowLocationSharing'],
        'flexiblePickupTimes': widget.initialData!['flexiblePickupTimes'],
        // Add GPS coordinates - departure is always required, arrival is optional
        if (widget.initialData!['departurePoint'] != null) 'departurePoint': widget.initialData!['departurePoint'],
        if (widget.initialData!['arrivalPoint'] != null) 'arrivalPoint': widget.initialData!['arrivalPoint'],
      };

      // Debug logging
      print('DEBUG: Trip data being sent to backend:');
      print('DEBUG: pickupMode: ${tripData['pickupMode']}');
      print('DEBUG: pickupPoints: ${tripData['pickupPoints']}');
      print('DEBUG: Full trip data: $tripData');

      await _tripService.createTrip(tripData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trip created successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Go back to the dashboard and clear intermediate wizard pages
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to create trip: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  IconData _getOptionIcon(String optionName) {
    switch (optionName.toLowerCase()) {
      case 'air conditioning':
        return Icons.ac_unit;
      case 'heating':
        return Icons.thermostat;
      case 'smoking allowed':
        return Icons.smoking_rooms;
      case 'pet friendly':
        return Icons.pets;
      case 'bluetooth audio':
        return Icons.bluetooth;
      case 'wifi hotspot':
        return Icons.wifi;
      case 'extra luggage space':
        return Icons.luggage;
      case 'music':
        return Icons.music_note;
      case 'charging port':
        return Icons.battery_charging_full;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('DEBUG: Back button pressed in TripOptionsScreen');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Options',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add optional services to your trip',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  // Trip Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Route: ${widget.initialData?['departureCity']['name']} → ${widget.initialData?['arrivalCity']['name']}'),
                        if (widget.initialData?['departureTime'] != null)
                          Text('Departure: ${widget.initialData!['departureTime'].day}/${widget.initialData!['departureTime'].month}/${widget.initialData!['departureTime'].year} at ${widget.initialData!['departureTime'].hour.toString().padLeft(2, '0')}:${widget.initialData!['departureTime'].minute.toString().padLeft(2, '0')}'),
                        if (widget.initialData?['arrivalTime'] != null)
                          Text('Arrival: ${widget.initialData!['arrivalTime'].day}/${widget.initialData!['arrivalTime'].month}/${widget.initialData!['arrivalTime'].year} at ${widget.initialData!['arrivalTime'].hour.toString().padLeft(2, '0')}:${widget.initialData!['arrivalTime'].minute.toString().padLeft(2, '0')}'),
                        Text('Price: ${widget.initialData?['price']} coins per seat'),
                        Text('Seats: ${widget.initialData?['maxSeats']}'),
                        Text('Pickup: ${widget.initialData?['pickupMode'] == 'DESIGNATED_POINT' ? 'Designated Points' : 'Individual Pickup'}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  const Text(
                    'Available Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = _selectedOptions.contains(option['id']);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getOptionIcon(option['name']),
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Text(option['name']),
                            subtitle: Text(option['description'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${option['price']} coins',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedOptions.add(option['id']);
                                      } else {
                                        _selectedOptions.remove(option['id']);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedOptions.remove(option['id']);
                                } else {
                                  _selectedOptions.add(option['id']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Create Trip Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _createTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaving ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Creating Trip...'),
                              ],
                            )
                          : const Text('Create Trip'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
