import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permissions
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permissions
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Get location updates
  static Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Calculate distance between two points
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Get coordinates from address
  static Future<Map<String, double>?> getCoordinatesFromAddress({
    required String address,
  }) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  // Get nearby trips based on location
  static Future<List<Map<String, dynamic>>> getNearbyTrips({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    required List<Map<String, dynamic>> allTrips,
  }) async {
    List<Map<String, dynamic>> nearbyTrips = [];

    for (var trip in allTrips) {
      if (trip['startPoint'] != null) {
        double distance = calculateDistance(
          startLatitude: latitude,
          startLongitude: longitude,
          endLatitude: trip['startPoint']['latitude'],
          endLongitude: trip['startPoint']['longitude'],
        );

        if (distance <= radiusInKm * 1000) { // Convert km to meters
          nearbyTrips.add({
            ...trip,
            'distance': distance,
          });
        }
      }
    }

    // Sort by distance
    nearbyTrips.sort((a, b) => a['distance'].compareTo(b['distance']));
    return nearbyTrips;
  }

  // Track trip progress
  static Stream<Map<String, dynamic>> trackTripProgress({
    required double startLatitude,
    required double endLatitude,
    required double startLongitude,
    required double endLongitude,
  }) async* {
    await for (Position position in getLocationUpdates()) {
      double distanceToStart = calculateDistance(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: startLatitude,
        endLongitude: startLongitude,
      );

      double distanceToEnd = calculateDistance(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
      );

      double totalDistance = calculateDistance(
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
      );

      double progress = (distanceToStart / totalDistance) * 100;

      yield {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'distanceToStart': distanceToStart,
        'distanceToEnd': distanceToEnd,
        'totalDistance': totalDistance,
        'progress': progress,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get location permission status
  static Future<Map<String, dynamic>> getLocationStatus() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    LocationPermission permission = await checkPermission();

    return {
      'serviceEnabled': serviceEnabled,
      'permission': permission.toString(),
      'canGetLocation': serviceEnabled && 
                       permission != LocationPermission.denied && 
                       permission != LocationPermission.deniedForever,
    };
  }
}


