import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SimpleLocationPickerWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final Map<String, dynamic>? initialLocation;
  final String title;
  final Map<String, dynamic>? cityInfo; // City information for boundary restriction
  final bool restrictToCity; // Whether to restrict selection to city boundaries

  const SimpleLocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.title = 'Select Location',
    this.cityInfo,
    this.restrictToCity = false,
  });

  @override
  State<SimpleLocationPickerWidget> createState() => _SimpleLocationPickerWidgetState();
}

class _SimpleLocationPickerWidgetState extends State<SimpleLocationPickerWidget> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  
  MapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  bool _showMap = false;

  // Default location (Tunis, Tunisia)
  static const LatLng _defaultLocation = LatLng(36.8065, 10.1815);
  
  // City boundary validation
  bool _isWithinCityBounds(LatLng location) {
    if (!widget.restrictToCity || widget.cityInfo == null) return true;
    
    final cityLat = widget.cityInfo!['latitude'] as double?;
    final cityLng = widget.cityInfo!['longitude'] as double?;
    
    if (cityLat == null || cityLng == null) return true;
    
    // Define a reasonable city boundary (approximately 20km radius)
    const double cityRadiusKm = 20.0;
    const double earthRadiusKm = 6371.0;
    
    // Calculate distance between selected point and city center
    double lat1Rad = cityLat * (3.14159265359 / 180);
    double lat2Rad = location.latitude * (3.14159265359 / 180);
    double deltaLatRad = (location.latitude - cityLat) * (3.14159265359 / 180);
    double deltaLngRad = (location.longitude - cityLng) * (3.14159265359 / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));
    double distanceKm = earthRadiusKm * c;
    
    return distanceKm <= cityRadiusKm;
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _addressController.text = widget.initialLocation!['address'] ?? '';
      _latitudeController.text = widget.initialLocation!['latitude']?.toString() ?? '';
      _longitudeController.text = widget.initialLocation!['longitude']?.toString() ?? '';
      _selectedLocation = LatLng(
        widget.initialLocation!['latitude'] as double,
        widget.initialLocation!['longitude'] as double,
      );
    }
  }
  
  LatLng _getInitialMapCenter() {
    // If we have city info and restriction is enabled, center on city
    if (widget.restrictToCity && widget.cityInfo != null) {
      final cityLat = widget.cityInfo!['latitude'] as double?;
      final cityLng = widget.cityInfo!['longitude'] as double?;
      if (cityLat != null && cityLng != null) {
        return LatLng(cityLat, cityLng);
      }
    }
    
    // Otherwise use selected location or default
    return _selectedLocation ?? _defaultLocation;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
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
            onPressed: _confirmLocation,
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = false),
                    icon: Icon(Icons.edit_location),
                    label: Text('Manual Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showMap ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = true),
                    icon: Icon(Icons.map),
                    label: Text('Map Selection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showMap ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _showMap ? _buildMapView() : _buildManualEntry(),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Location Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Enter the pickup point address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latitude and longitude are automatically filled when you select a location on the map or use quick select buttons.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Latitude (Auto-filled)',
                    hintText: 'Select location on map',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    suffixIcon: _selectedLocation != null 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.location_searching, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Longitude (Auto-filled)',
                    hintText: 'Select location on map',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    suffixIcon: _selectedLocation != null 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.location_searching, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Select:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickLocationButton('Tunis Center', 'Tunis, Tunisia', 36.8065, 10.1815),
              _buildQuickLocationButton('Sfax Center', 'Sfax, Tunisia', 34.7406, 10.7603),
              _buildQuickLocationButton('Sousse Center', 'Sousse, Tunisia', 35.8256, 10.6411),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _getInitialMapCenter(),
            zoom: 14.0,
            onTap: (tapPosition, point) {
              // Check if point is within city bounds if restriction is enabled
              if (widget.restrictToCity && !_isWithinCityBounds(point)) {
                _showErrorSnackBar('Please select a location within ${widget.cityInfo?['name'] ?? 'the selected city'}');
                return;
              }
              
              setState(() {
                _selectedLocation = point;
                _latitudeController.text = point.latitude.toString();
                _longitudeController.text = point.longitude.toString();
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
            // City boundary circle (if restriction is enabled)
            if (widget.restrictToCity && widget.cityInfo != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      widget.cityInfo!['latitude'] as double,
                      widget.cityInfo!['longitude'] as double,
                    ),
                    radius: 20000, // 20km radius
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
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
                  widget.restrictToCity 
                    ? 'Tap on the map to select pickup point within ${widget.cityInfo?['name'] ?? 'the selected city'}'
                    : 'Tap on the map to select pickup point',
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
    );
  }

  Widget _buildQuickLocationButton(String name, String address, double lat, double lng) {
    return ElevatedButton(
      onPressed: () {
        _addressController.text = address;
        _latitudeController.text = lat.toString();
        _longitudeController.text = lng.toString();
        setState(() {
          _selectedLocation = LatLng(lat, lng);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
      ),
      child: Text(name),
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
        _latitudeController.text = location.latitude.toString();
        _longitudeController.text = location.longitude.toString();
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
          _addressController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
        _addressController.text = _selectedAddress!;
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

  void _confirmLocation() {
    // If we have a selected location from the map, use that
    if (_selectedLocation != null) {
      final address = _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : _selectedAddress ?? 'Selected location';
      
      final locationData = {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': address,
      };

      widget.onLocationSelected(locationData);
      Navigator.of(context).pop();
      return;
    }

    // Otherwise, validate manual entry
    final address = _addressController.text.trim();
    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();

    if (address.isEmpty) {
      _showErrorSnackBar('Please enter an address');
      return;
    }

    if (latitudeText.isEmpty || longitudeText.isEmpty) {
      _showErrorSnackBar('Please enter latitude and longitude coordinates');
      return;
    }

    final latitude = double.tryParse(latitudeText);
    final longitude = double.tryParse(longitudeText);

    if (latitude == null || longitude == null) {
      _showErrorSnackBar('Please enter valid coordinates');
      return;
    }

    if (latitude < -90 || latitude > 90) {
      _showErrorSnackBar('Latitude must be between -90 and 90');
      return;
    }

    if (longitude < -180 || longitude > 180) {
      _showErrorSnackBar('Longitude must be between -180 and 180');
      return;
    }

    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };

    widget.onLocationSelected(locationData);
    Navigator.of(context).pop();
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