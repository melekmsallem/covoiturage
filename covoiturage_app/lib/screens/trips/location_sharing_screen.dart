import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_tracking_service.dart';
import '../../services/api_service.dart';

class LocationSharingScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Map<String, dynamic>? pickupPoint;

  const LocationSharingScreen({
    super.key,
    required this.trip,
    this.pickupPoint,
  });

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  bool _isSharing = false;
  bool _isLoading = false;
  String? _statusMessage;
  double? _distanceFromPickup;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    if (_isSharing) {
      _stopLocationSharing();
    }
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool isEnabled = await _locationService.isLocationServiceEnabled();
    if (!isEnabled) {
      setState(() {
        _statusMessage = 'Please enable location services to share your location';
      });
      return;
    }

    LocationPermission permission = await _locationService.checkLocationPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestLocationPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'Location permissions are permanently denied. Please enable them in settings.';
      });
    }
  }

  Future<void> _startLocationSharing() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Start location tracking
      bool started = await _locationService.startLocationTracking(
        onLocationUpdate: (position) {
          setState(() {
            _isSharing = true;
            _isLoading = false;
            _statusMessage = 'Location sharing active';
          });
          _updateDistanceFromPickup(position);
        },
        onLocationError: (error) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Location sharing error: $error';
          });
        },
      );

      if (started) {
        // Notify backend about location sharing
        await _notifyBackendLocationSharing(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Failed to start location sharing: $e';
      });
    }
  }

  Future<void> _stopLocationSharing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _locationService.stopLocationTracking();
      await _notifyBackendLocationSharing(false);
      
      setState(() {
        _isSharing = false;
        _isLoading = false;
        _statusMessage = 'Location sharing stopped';
        _distanceFromPickup = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Failed to stop location sharing: $e';
      });
    }
  }

  Future<void> _notifyBackendLocationSharing(bool isSharing) async {
    try {
      final endpoint = isSharing ? '/location/share' : '/location/stop-sharing';
      await ApiService.instance.post(endpoint, {
        'tripId': widget.trip['id'],
      });
    } catch (e) {
      debugPrint('Failed to notify backend about location sharing: $e');
    }
  }

  void _updateDistanceFromPickup(Position position) {
    if (widget.pickupPoint != null) {
      double distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        widget.pickupPoint!['latitude'] as double,
        widget.pickupPoint!['longitude'] as double,
      );
      
      setState(() {
        _distanceFromPickup = distance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trip info card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'From: ${widget.trip['departureCity'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'To: ${widget.trip['arrivalCity'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (widget.pickupPoint != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pickup: ${widget.pickupPoint!['address'] ?? 'Designated point'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Location sharing status
            Card(
              elevation: 4,
              color: _isSharing ? Colors.green.shade50 : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isSharing ? Icons.location_on : Icons.location_off,
                      size: 48,
                      color: _isSharing ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSharing ? 'Location Sharing Active' : 'Location Sharing Inactive',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isSharing ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isSharing ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_distanceFromPickup != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _distanceFromPickup! <= 100 ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _distanceFromPickup! <= 100 ? Icons.check_circle : Icons.warning,
                              color: _distanceFromPickup! <= 100 ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Distance from pickup: ${_distanceFromPickup!.toStringAsFixed(0)}m',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _distanceFromPickup! <= 100 ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ElevatedButton(
                onPressed: _isSharing ? _stopLocationSharing : _startLocationSharing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isSharing ? 'Stop Sharing Location' : 'Start Sharing Location',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Info text
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
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Why share location?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Driver can see your real-time location\n'
                    '• Helps driver find you easily\n'
                    '• Shows if you\'re in the pickup area\n'
                    '• Improves trip coordination',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
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
}
