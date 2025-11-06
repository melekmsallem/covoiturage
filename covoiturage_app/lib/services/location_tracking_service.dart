import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;
  Position? _currentPosition;
  bool _isTracking = false;

  // Callbacks for location updates
  Function(Position)? onLocationUpdate;
  Function(String)? onLocationError;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  /// Start real-time location tracking
  Future<bool> startLocationTracking({
    Duration updateInterval = const Duration(seconds: 30),
    required Function(Position) onLocationUpdate,
    required Function(String) onLocationError,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onLocationError('Location services are disabled. Please enable them.');
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onLocationError('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onLocationError('Location permissions are permanently denied.');
        return false;
      }

      // Set callbacks
      this.onLocationUpdate = onLocationUpdate;
      this.onLocationError = onLocationError;

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (_currentPosition != null) {
        onLocationUpdate(_currentPosition!);
      }

      // Start position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate(position);
          _sendLocationToServer(position);
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
          onLocationError('Location tracking error: $error');
        },
      );

      _isTracking = true;
      debugPrint('Location tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
      onLocationError('Failed to start location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _isTracking = false;
    _currentPosition = null;
    debugPrint('Location tracking stopped');
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return position;
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }

  /// Send location to server
  Future<void> _sendLocationToServer(Position position) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await ApiService.instance.post('/location/update', locationData);
    } catch (e) {
      debugPrint('Failed to send location to server: $e');
    }
  }

  /// Check if location is within designated pickup area
  Future<bool> isWithinPickupArea({
    required double pickupLatitude,
    required double pickupLongitude,
    required double radiusInMeters,
  }) async {
    if (_currentPosition == null) {
      return false;
    }

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pickupLatitude,
      pickupLongitude,
    );

    return distance <= radiusInMeters;
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _buildAddressString(place);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get address from coordinates: $e');
      return null;
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

  /// Calculate distance between two points
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }
}















