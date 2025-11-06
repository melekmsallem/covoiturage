import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OpenStreetMapRouteService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  
  /// Get route between two points using OSRM (free, no API key required)
  static Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Build coordinates string
      String coordinates = '${start.longitude},${start.latitude}';
      
      if (waypoints != null && waypoints.isNotEmpty) {
        for (var waypoint in waypoints) {
          coordinates += ';${waypoint.longitude},${waypoint.latitude}';
        }
      }
      
      coordinates += ';${end.longitude},${end.latitude}';
      
      // Build URL
      final url = '$_baseUrl/driving/$coordinates?overview=full&geometries=polyline';
      
      print('DEBUG: Requesting route from OSRM: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = route['distance'];
          final duration = route['duration'];
          
          // Decode polyline geometry to get route points
          List<LatLng> routePoints = _decodePolyline(geometry);
          
          return RouteResult(
            points: routePoints,
            distance: distance,
            duration: duration,
            distanceText: _formatDistance(distance),
            durationText: _formatDuration(duration),
          );
        }
      }
      
      print('DEBUG: OSRM route failed: ${response.statusCode} - ${response.body}');
      return null;
      
    } catch (e) {
      print('DEBUG: Error getting route: $e');
      return null;
    }
  }
  
  /// Get multiple routes (alternative routes)
  static Future<List<RouteResult>> getAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    int alternatives = 3,
  }) async {
    try {
      final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      final url = '$_baseUrl/driving/$coordinates?overview=full&geometries=polyline&alternatives=$alternatives';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok') {
          List<RouteResult> routes = [];
          
          for (var route in data['routes']) {
            final geometry = route['geometry'];
            final distance = route['distance'];
            final duration = route['duration'];
            
            List<LatLng> routePoints = _decodePolyline(geometry);
            
            routes.add(RouteResult(
              points: routePoints,
              distance: distance,
              duration: duration,
              distanceText: _formatDistance(distance),
              durationText: _formatDuration(duration),
            ));
          }
          
          return routes;
        }
      }
      
      return [];
      
    } catch (e) {
      print('DEBUG: Error getting alternative routes: $e');
      return [];
    }
  }
  
  /// Search for places using Nominatim (free, no API key required)
  static Future<List<PlaceResult>> searchPlaces(String query, {int limit = 10}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CovoiturageApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((item) => PlaceResult(
          name: item['display_name'] ?? '',
          latitude: double.parse(item['lat']),
          longitude: double.parse(item['lon']),
          type: item['type'] ?? '',
          importance: item['importance']?.toDouble() ?? 0.0,
        )).toList();
      }
      
      return [];
      
    } catch (e) {
      print('DEBUG: Error searching places: $e');
      return [];
    }
  }
  
  /// Reverse geocoding - get address from coordinates
  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=${coordinates.latitude}&lon=${coordinates.longitude}&format=json&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CovoiturageApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      
      return null;
      
    } catch (e) {
      print('DEBUG: Error getting address: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }
  
  /// Calculate bearing between two points
  static double calculateBearing(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.bearing(point1, point2);
  }
  
  // Helper methods
  static List<LatLng> _decodePolyline(String polyline) {
    // This is a simplified polyline decoder
    // For production, use a proper polyline decoder library
    List<LatLng> points = [];
    
    try {
      // Split the polyline into coordinate pairs
      List<String> pairs = polyline.split(';');
      
      for (String pair in pairs) {
        List<String> coords = pair.split(',');
        if (coords.length == 2) {
          double lon = double.parse(coords[0]);
          double lat = double.parse(coords[1]);
          points.add(LatLng(lat, lon));
        }
      }
    } catch (e) {
      print('DEBUG: Error decoding polyline: $e');
    }
    
    return points;
  }
  
  static String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
  
  static String _formatDuration(double durationInSeconds) {
    int hours = (durationInSeconds / 3600).floor();
    int minutes = ((durationInSeconds % 3600) / 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class RouteResult {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds
  final String distanceText;
  final String durationText;
  
  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.distanceText,
    required this.durationText,
  });
}

class PlaceResult {
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final double importance;
  
  PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.importance,
  });
  
  LatLng get coordinates => LatLng(latitude, longitude);
}














