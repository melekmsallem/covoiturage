import 'package:flutter/material.dart';
import '../../../widgets/simple_location_picker_widget.dart';
import 'trip_options_screen.dart';

class PickupModeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onNext;

  const PickupModeScreen({
    super.key,
    this.initialData,
    required this.onNext,
  });

  @override
  State<PickupModeScreen> createState() => _PickupModeScreenState();
}

class _PickupModeScreenState extends State<PickupModeScreen> {
  String? _selectedPickupMode;
  List<Map<String, dynamic>> _pickupPoints = [];
  bool _allowLocationSharing = true;
  bool _flexiblePickupTimes = true;
  Map<String, dynamic>? _departurePoint;
  Map<String, dynamic>? _arrivalPoint;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      setState(() {
        _selectedPickupMode = widget.initialData!['pickupMode'] ?? 'DESIGNATED_POINT'; // Default to designated point
        _pickupPoints = List<Map<String, dynamic>>.from(widget.initialData!['pickupPoints'] ?? []);
        _allowLocationSharing = widget.initialData!['allowLocationSharing'] ?? true;
        _flexiblePickupTimes = widget.initialData!['flexiblePickupTimes'] ?? true;
        _departurePoint = widget.initialData!['departurePoint'];
        _arrivalPoint = widget.initialData!['arrivalPoint'];
      });
    } else {
      // Set default pickup mode if no initial data
      setState(() {
        _selectedPickupMode = 'DESIGNATED_POINT';
      });
    }
    
    // Debug logging
    print('DEBUG: Pickup mode screen loaded with pickupMode: $_selectedPickupMode');
    print('DEBUG: Initial data: ${widget.initialData}');
  }

  void _nextStep() {
    if (_selectedPickupMode == null) {
      _showErrorSnackBar('Please select a pickup mode');
      return;
    }
    if (_selectedPickupMode == 'DESIGNATED_POINT' && _departurePoint == null) {
      _showErrorSnackBar('Please set a departure point for designated pickup');
      return;
    }

    // Debug logging
    print('DEBUG: Pickup mode selected: $_selectedPickupMode');
    print('DEBUG: Departure point: $_departurePoint');
    print('DEBUG: Pickup points: $_pickupPoints');

    final payload = {
      'pickupMode': _selectedPickupMode,
      'pickupPoints': _pickupPoints,
      'allowLocationSharing': _allowLocationSharing,
      'flexiblePickupTimes': _flexiblePickupTimes,
      'departurePoint': _departurePoint,
      'arrivalPoint': _arrivalPoint,
    };
    widget.onNext(payload);
    // Also navigate directly to TripOptions to avoid upstream context issues
    try {
      final merged = {
        ...?widget.initialData,
        ...payload,
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripOptionsScreen(
            initialData: merged,
            onCreateTrip: (_) {},
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigation to TripOptions failed: $e');
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

  void _setDeparturePoint(Map<String, dynamic> location) {
    setState(() {
      _departurePoint = location;
    });
  }


  void _addPickupPoint() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleLocationPickerWidget(
          title: 'Add Pickup Point',
          onLocationSelected: (location) {
            setState(() {
              _pickupPoints.add({
                'address': location['address'],
                'latitude': location['latitude'],
                'longitude': location['longitude'],
                'pickupTime': widget.initialData?['departureTime']?.toIso8601String(),
                'maxWaitingTime': 10,
              });
            });
          },
          cityInfo: widget.initialData?['departureCity'],
          restrictToCity: true,
        ),
      ),
    );
  }

  Widget _buildPickupPointCard(int index) {
    final point = _pickupPoints[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text('${index + 2}'), // Start from 2 since departure is 1
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Point ${index + 2}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  point['address'] ?? 'Selected location',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _pickupPoints.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Remove pickup point',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Options'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text(
              'Pickup Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how passengers will be picked up',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            // Pickup Mode Selection
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 520
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2,
                  child: RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: const Text('Designated Pickup'),
                    subtitle: const Text('Set specific pickup locations'),
                    value: 'DESIGNATED_POINT',
                    groupValue: _selectedPickupMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupMode = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 520
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2,
                  child: RadioListTile<String>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: const Text('Individual Pickup'),
                    subtitle: const Text('Passengers share live location'),
                    value: 'INDIVIDUAL_PICKUP',
                    groupValue: _selectedPickupMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedPickupMode = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // GPS Coordinate Selection for Departure
            if (_selectedPickupMode == 'DESIGNATED_POINT') ...[
              const Text(
                'Departure Point',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleLocationPickerWidget(
                              title: 'Select Departure Point',
                              onLocationSelected: _setDeparturePoint,
                              initialLocation: _departurePoint,
                              cityInfo: widget.initialData?['departureCity'],
                              restrictToCity: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.my_location),
                      label: Text(_departurePoint != null 
                          ? 'Update Departure Point' 
                          : 'Set Departure Point'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_departurePoint != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _departurePoint = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Clear departure point',
                    ),
                ],
              ),
              if (_departurePoint != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_departurePoint!['address'] ?? 'Selected location'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            
            // Individual Pickup Settings
            if (_selectedPickupMode == 'INDIVIDUAL_PICKUP') ...[
              const SizedBox(height: 16),
              const Text(
                'Individual Pickup Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Allow Location Sharing'),
                subtitle: const Text('Passengers can share their location with you'),
                value: _allowLocationSharing,
                onChanged: (value) {
                  setState(() {
                    _allowLocationSharing = value;
                  });
                },
                activeColor: Colors.green,
              ),
              SwitchListTile(
                title: const Text('Flexible Pickup Times'),
                subtitle: const Text('Allow flexible pickup time windows'),
                value: _flexiblePickupTimes,
                onChanged: (value) {
                  setState(() {
                    _flexiblePickupTimes = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
            
            // Designated Pickup Points Management
            if (_selectedPickupMode == 'DESIGNATED_POINT') ...[
              const SizedBox(height: 16),
              const Text(
                'Pickup Points',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Show departure point as first pickup point
              if (_departurePoint != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Text('1', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Departure Point (Automatic)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _departurePoint!['address'] ?? 'Selected location',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Show additional pickup points
              if (_pickupPoints.isNotEmpty) ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pickupPoints.length,
                  itemBuilder: (context, index) {
                    return _buildPickupPointCard(index);
                  },
                ),
                const SizedBox(height: 8),
              ],
              
              // Add pickup point button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _departurePoint != null ? _addPickupPoint : null,
                  icon: const Icon(Icons.add_location),
                  label: Text(_departurePoint != null 
                      ? 'Add Additional Pickup Point' 
                      : 'Set Departure Point First'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _departurePoint != null ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}
