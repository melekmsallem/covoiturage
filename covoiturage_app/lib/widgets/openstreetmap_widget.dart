import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OpenStreetMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<LatLng>? waypoints;
  final bool showCurrentLocation;
  final bool allowLocationSelection;
  final Function(LatLng)? onLocationSelected;
  final Function(LatLng)? onLocationChanged;
  final double height;
  final double zoom;

  const OpenStreetMapWidget({
    Key? key,
    this.initialLocation,
    this.waypoints,
    this.showCurrentLocation = true,
    this.allowLocationSelection = false,
    this.onLocationSelected,
    this.onLocationChanged,
    this.height = 400,
    this.zoom = 13.0,
  }) : super(key: key);

  @override
  _OpenStreetMapWidgetState createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  late MapController _mapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current location
      if (widget.showCurrentLocation) {
        await _getCurrentLocation();
      }
      
      // Set initial location
      if (widget.initialLocation != null) {
        _selectedLocation = widget.initialLocation;
      }
      
      // Load waypoints if provided
      if (widget.waypoints != null) {
        _routePoints = List.from(widget.waypoints!);
      }
      
    } catch (e) {
      print('Error initializing location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Start real-time location tracking
      _startLocationTracking();
      
    } catch (e) {
      print('Error getting current location: $e');
      _showLocationError(e.toString());
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Notify parent widget of location changes
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(_currentLocation!);
      }
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.allowLocationSelection) {
      setState(() {
        _selectedLocation = point;
      });
      
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(point);
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng newLocation = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        
        setState(() {
          _selectedLocation = newLocation;
        });
        
        _mapController.move(newLocation, _mapController.camera.zoom);
        
        if (widget.onLocationSelected != null) {
          widget.onLocationSelected!(newLocation);
        }
      }
    } catch (e) {
      print('Error searching location: $e');
      _showSearchError('Location not found');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location Error: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSearchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation ?? 
                     _selectedLocation ?? 
                     widget.initialLocation ?? 
                     LatLng(51.5, -0.09), // Default to London
              zoom: widget.zoom,
              onTap: _onMapTap,
            ),
            children: [
              // Base map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.covoiturage.covoiturage_app',
                maxZoom: 18,
              ),
              
              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Selected location marker
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Route polylines
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Search bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: _buildSearchBar(),
          ),
          
          // Location info
          if (_selectedLocation != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: _buildLocationInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for a location...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: _searchLocation,
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: FutureBuilder<String>(
              future: _getAddressFromCoordinates(_selectedLocation!),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Loading address...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Real-time location tracking widget
class RealtimeLocationMap extends StatefulWidget {
  final Function(LatLng)? onLocationUpdate;
  final List<LatLng>? otherUsers;
  final double height;

  const RealtimeLocationMap({
    Key? key,
    this.onLocationUpdate,
    this.otherUsers,
    this.height = 300,
  }) : super(key: key);

  @override
  _RealtimeLocationMapState createState() => _RealtimeLocationMapState();
}

class _RealtimeLocationMapState extends State<RealtimeLocationMap> {
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = newLocation;
      });
      
      if (widget.onLocationUpdate != null) {
        widget.onLocationUpdate!(newLocation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: _currentLocation!,
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.covoiturage.covoiturage_app',
                ),
                MarkerLayer(
                  markers: [
                    // Current user
                    Marker(
                      point: _currentLocation!,
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                    // Other users
                    if (widget.otherUsers != null)
                      ...widget.otherUsers!.map((location) => Marker(
                        point: location,
                        builder: (ctx) => Container(
                          child: Icon(
                            Icons.person,
                            color: Colors.green,
                            size: 25,
                          ),
                        ),
                      )),
                  ],
                ),
              ],
            ),
    );
  }
}














