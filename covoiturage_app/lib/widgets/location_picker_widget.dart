import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final Map<String, dynamic>? initialLocation;
  final String title;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.title = 'Select Location',
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  MapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  // Default location (Tunis, Tunisia)
  static const LatLng _defaultLocation = LatLng(36.8065, 10.1815);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!['latitude'] as double,
        widget.initialLocation!['longitude'] as double,
      );
      _selectedAddress = widget.initialLocation!['address'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null ? _confirmLocation : null,
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _selectedLocation ?? _defaultLocation,
              zoom: 14.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _getAddressFromCoordinates(point);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.covoiturage.covoiturage_app',
                maxZoom: 18,
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // Instructions
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap on the map to select a location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Current location button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled. Please enable them.');
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = location;
      });

      // Move camera to current location
      _mapController?.move(location, 16.0);

      // Get address for current location
      await _getAddressFromCoordinates(location);
    } catch (e) {
      _showErrorSnackBar('Failed to get current location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _buildAddressString(place);
        
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
      });
    }
  }

  String _buildAddressString(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown location';
  }

  void _confirmLocation() async {
    if (_selectedLocation != null) {
      final locationData = {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress ?? 'Selected location',
      };

      widget.onLocationSelected(locationData);
      Navigator.of(context).pop();
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
}