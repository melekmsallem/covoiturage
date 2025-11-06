import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_tracking_service.dart';

class RealtimeLocationMap extends StatefulWidget {
  final List<Map<String, dynamic>> passengers;
  final Map<String, dynamic>? pickupPoint;
  final double pickupRadius; // in meters
  final Function(Map<String, dynamic>)? onPassengerSelected;

  const RealtimeLocationMap({
    super.key,
    required this.passengers,
    this.pickupPoint,
    this.pickupRadius = 100.0, // 100 meters default
    this.onPassengerSelected,
  });

  @override
  State<RealtimeLocationMap> createState() => _RealtimeLocationMapState();
}

class _RealtimeLocationMapState extends State<RealtimeLocationMap> {
  MapController? _mapController;
  final LocationTrackingService _locationService = LocationTrackingService();
  
  List<Marker> _markers = [];
  List<CircleMarker> _circles = [];
  
  // Default location (Tunis, Tunisia)
  static const LatLng _defaultLocation = LatLng(36.8065, 10.1815);
  LatLng _center = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _setupMap();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }

  void _setupMap() {
    _updateMarkers();
    _updateCircles();
    
    // Set initial center to pickup point if available
    if (widget.pickupPoint != null) {
      _center = LatLng(
        widget.pickupPoint!['latitude'] as double,
        widget.pickupPoint!['longitude'] as double,
      );
    }
  }

  void _startLocationUpdates() {
    // Start tracking driver's location
    _locationService.startLocationTracking(
      onLocationUpdate: (position) {
        if (mounted) {
          setState(() {
            _center = LatLng(position.latitude, position.longitude);
            _updateMarkers();
          });
          
          // Move camera to driver's location
          _mapController?.move(
            LatLng(position.latitude, position.longitude),
            15.0,
          );
        }
      },
      onLocationError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      },
    );

    // Fetch passenger locations periodically
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchPassengerLocations();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchPassengerLocations() async {
    try {
      // This would fetch real-time passenger locations from your backend
      // For now, we'll simulate with the passengers list
      setState(() {
        _updateMarkers();
      });
    } catch (e) {
      debugPrint('Failed to fetch passenger locations: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add pickup point marker
    if (widget.pickupPoint != null) {
      _markers.add(
        Marker(
          point: LatLng(
            widget.pickupPoint!['latitude'] as double,
            widget.pickupPoint!['longitude'] as double,
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.green,
            size: 30,
          ),
        ),
      );
    }

    // Add driver's current location marker
    if (_locationService.currentPosition != null) {
      _markers.add(
        Marker(
          point: LatLng(
            _locationService.currentPosition!.latitude,
            _locationService.currentPosition!.longitude,
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }

    // Add passenger markers
    for (int i = 0; i < widget.passengers.length; i++) {
      final passenger = widget.passengers[i];
      if (passenger['latitude'] != null && passenger['longitude'] != null) {
        final isWithinRadius = _isPassengerWithinPickupArea(passenger);
        
        _markers.add(
          Marker(
            point: LatLng(
              passenger['latitude'] as double,
              passenger['longitude'] as double,
            ),
            child: GestureDetector(
              onTap: () {
                if (widget.onPassengerSelected != null) {
                  widget.onPassengerSelected!(passenger);
                }
              },
              child: Icon(
                Icons.person,
                color: isWithinRadius ? Colors.green : Colors.red,
                size: 25,
              ),
            ),
          ),
        );
      }
    }
  }

  void _updateCircles() {
    _circles.clear();
    
    // Add pickup area circle
    if (widget.pickupPoint != null) {
      _circles.add(
        CircleMarker(
          point: LatLng(
            widget.pickupPoint!['latitude'] as double,
            widget.pickupPoint!['longitude'] as double,
          ),
          radius: widget.pickupRadius,
          useRadiusInMeter: true,
          color: Colors.green,
          borderColor: Colors.green,
          borderStrokeWidth: 2,
        ),
      );
    }
  }

  bool _isPassengerWithinPickupArea(Map<String, dynamic> passenger) {
    if (widget.pickupPoint == null || 
        passenger['latitude'] == null || 
        passenger['longitude'] == null) {
      return false;
    }

    final distance = _locationService.calculateDistance(
      widget.pickupPoint!['latitude'] as double,
      widget.pickupPoint!['longitude'] as double,
      passenger['latitude'] as double,
      passenger['longitude'] as double,
    );

    return distance <= widget.pickupRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Location Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPassengerLocations,
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _center,
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.covoiturage.covoiturage_app',
                maxZoom: 18,
              ),
              MarkerLayer(markers: _markers),
              CircleLayer(circles: _circles),
            ],
          ),
          
          // Legend
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(
                    icon: Icons.my_location,
                    color: Colors.blue,
                    text: 'Driver',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    icon: Icons.person,
                    color: Colors.green,
                    text: 'Passenger (in area)',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    icon: Icons.person,
                    color: Colors.red,
                    text: 'Passenger (outside)',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    icon: Icons.location_on,
                    color: Colors.green,
                    text: 'Pickup Point',
                  ),
                ],
              ),
            ),
          ),
          
          // Passenger list
          if (widget.passengers.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Passengers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.passengers.length,
                        itemBuilder: (context, index) {
                          final passenger = widget.passengers[index];
                          final isWithinRadius = _isPassengerWithinPickupArea(passenger);
                          
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isWithinRadius ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isWithinRadius ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  color: isWithinRadius ? Colors.green : Colors.red,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  passenger['firstName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isWithinRadius ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  isWithinRadius ? 'In Area' : 'Outside',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isWithinRadius ? Colors.green.shade600 : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}