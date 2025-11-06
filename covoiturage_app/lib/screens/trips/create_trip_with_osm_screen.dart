import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/openstreetmap_widget.dart';
import '../../services/openstreetmap_route_service.dart';

class CreateTripWithOSMScreen extends StatefulWidget {
  const CreateTripWithOSMScreen({super.key});

  @override
  State<CreateTripWithOSMScreen> createState() => _CreateTripWithOSMScreenState();
}

class _CreateTripWithOSMScreenState extends State<CreateTripWithOSMScreen> {
  LatLng? _departureLocation;
  LatLng? _arrivalLocation;
  List<LatLng> _waypoints = [];
  RouteResult? _currentRoute;
  bool _isLoadingRoute = false;
  List<PlaceResult> _searchResults = [];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip with OpenStreetMap'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Map
          Expanded(
            flex: 2,
            child: OpenStreetMapWidget(
              initialLocation: _departureLocation,
              waypoints: _waypoints,
              showCurrentLocation: true,
              allowLocationSelection: true,
              onLocationSelected: _onLocationSelected,
              height: 400,
            ),
          ),
          
          // Route information
          if (_currentRoute != null) _buildRouteInfo(),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for departure or arrival location...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(top: BorderSide(color: Colors.blue.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.straighten, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text('Distance: ${_currentRoute!.distanceText}'),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text('Duration: ${_currentRoute!.durationText}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _departureLocation == null ? null : _setDepartureLocation,
              icon: Icon(Icons.location_on),
              label: Text('Set Departure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _arrivalLocation == null ? null : _setArrivalLocation,
              icon: Icon(Icons.flag),
              label: Text('Set Arrival'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canCalculateRoute() ? _calculateRoute : null,
              icon: _isLoadingRoute ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ) : Icon(Icons.route),
              label: Text('Calculate Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoadingRoute = true;
    });
    
    try {
      List<PlaceResult> results = await OpenStreetMapRouteService.searchPlaces(query);
      setState(() {
        _searchResults = results;
      });
      
      if (results.isNotEmpty) {
        _showSearchResults(results);
      }
    } catch (e) {
      _showError('Search failed: $e');
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _onLocationSelected(LatLng location) {
    // This will be called when user taps on the map
    setState(() {
      // You can implement logic to determine if this is departure or arrival
      if (_departureLocation == null) {
        _departureLocation = location;
      } else if (_arrivalLocation == null) {
        _arrivalLocation = location;
      }
    });
  }

  void _setDepartureLocation() {
    // Set current selected location as departure
    if (_departureLocation != null) {
      // Departure location set
    }
  }

  void _setArrivalLocation() {
    // Set current selected location as arrival
    if (_arrivalLocation != null) {
      // Arrival location set
    }
  }

  Future<void> _calculateRoute() async {
    if (!_canCalculateRoute()) return;
    
    setState(() {
      _isLoadingRoute = true;
    });
    
    try {
      RouteResult? route = await OpenStreetMapRouteService.getRoute(
        start: _departureLocation!,
        end: _arrivalLocation!,
        waypoints: _waypoints,
      );
      
      if (route != null) {
        setState(() {
          _currentRoute = route;
        });
        // Route calculated successfully
      } else {
        _showError('Failed to calculate route');
      }
    } catch (e) {
      _showError('Route calculation failed: $e');
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  bool _canCalculateRoute() {
    return _departureLocation != null && _arrivalLocation != null;
  }

  void _showSearchResults(List<PlaceResult> results) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text(result.name),
                    subtitle: Text('${result.type} • Importance: ${result.importance.toStringAsFixed(2)}'),
                    onTap: () {
                      Navigator.pop(context);
                      _selectSearchResult(result);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSearchResult(PlaceResult result) {
    setState(() {
      if (_departureLocation == null) {
        _departureLocation = result.coordinates;
      } else if (_arrivalLocation == null) {
        _arrivalLocation = result.coordinates;
      }
    });
    // Location selected: ${result.name}
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Real-time location tracking example
class RealtimeLocationExample extends StatefulWidget {
  @override
  _RealtimeLocationExampleState createState() => _RealtimeLocationExampleState();
}

class _RealtimeLocationExampleState extends State<RealtimeLocationExample> {
  LatLng? _currentLocation;
  List<LatLng> _otherUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Location Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Real-time map
          Expanded(
            child: RealtimeLocationMap(
              onLocationUpdate: (location) {
                setState(() {
                  _currentLocation = location;
                });
                print('Location updated: ${location.latitude}, ${location.longitude}');
              },
              otherUsers: _otherUsers,
              height: 400,
            ),
          ),
          
          // Location info
          if (_currentLocation != null)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Current Location:'),
                  Text('Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}'),
                  Text('Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}





