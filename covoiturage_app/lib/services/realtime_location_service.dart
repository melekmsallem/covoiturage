import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'websocket_service.dart';

/// Service for real-time location tracking via WebSocket
/// Handles both sending and receiving location updates between driver and passengers
class RealtimeLocationService {
  static final RealtimeLocationService _instance = RealtimeLocationService._internal();
  factory RealtimeLocationService() => _instance;
  RealtimeLocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _websocketSubscription;
  Timer? _heartbeatTimer;
  LocationTrackingState _trackingState = LocationTrackingState.stopped;

  // Current locations cache
  final Map<int, Map<String, dynamic>> _userLocations = {};
  
  // Callbacks
  Function(Map<String, dynamic>)? onLocationUpdate;
  Function(String)? onError;

  LocationTrackingState get trackingState => _trackingState;

  /// Start real-time location tracking for a trip
  Future<bool> startTracking({
    required int userId,
    required int tripId,
    required String userRole, // "DRIVER" or "PASSENGER"
    required Function(Map<String, dynamic>) onLocationUpdate,
    required Function(String) onError,
  }) async {
    try {
      // Check if already tracking
      if (_trackingState == LocationTrackingState.tracking) {
        debugPrint('Already tracking location');
        return true;
      }

      // Check location services and permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onError('Location services are disabled. Please enable them.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onError('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onError('Location permissions are permanently denied.');
        return false;
      }

      // Set callbacks
      this.onLocationUpdate = onLocationUpdate;
      this.onError = onError;

      // Connect to WebSocket if not already connected
      if (!WebSocketService.instance.isConnected) {
        await WebSocketService.instance.connect();
      }

      // Subscribe to trip-specific location updates
      _websocketSubscription = WebSocketService.instance.messageStream.listen(
        (message) {
          _handleWebSocketMessage(message, tripId, userId);
        },
      );

      // Seed with last known position if available (faster visibility)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final locationData = {
            'type': 'location-update',
            'userId': userId,
            'tripId': tripId,
            'userRole': userRole,
            'latitude': lastKnown.latitude,
            'longitude': lastKnown.longitude,
            'accuracy': lastKnown.accuracy,
            'speed': lastKnown.speed,
            'heading': lastKnown.heading,
            'timestamp': DateTime.now().toIso8601String(),
          };
          _userLocations[userId] = locationData;
          onLocationUpdate(locationData);
          _sendLocationUpdate(userId, tripId, userRole, lastKnown);
        }
      } catch (e) {
        debugPrint('Error getting last known position: $e');
      }

      // Get initial position immediately
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationData = {
          'type': 'location-update',
          'userId': userId,
          'tripId': tripId,
          'userRole': userRole,
          'latitude': initialPosition.latitude,
          'longitude': initialPosition.longitude,
          'accuracy': initialPosition.accuracy,
          'speed': initialPosition.speed,
          'heading': initialPosition.heading,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _userLocations[userId] = locationData;
        onLocationUpdate(locationData);
        _sendLocationUpdate(userId, tripId, userRole, initialPosition);
      } catch (e) {
        debugPrint('Error getting initial position: $e');
      }

      // Start GPS position stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          // Cache own location immediately
          final locationData = {
            'type': 'location-update',
            'userId': userId,
            'tripId': tripId,
            'userRole': userRole,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'speed': position.speed,
            'heading': position.heading,
            'timestamp': DateTime.now().toIso8601String(),
          };
          _userLocations[userId] = locationData;
          
          // Notify listeners
          onLocationUpdate(locationData);
          
          // Send to server
          _sendLocationUpdate(userId, tripId, userRole, position);
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
          onError('Location tracking error: $error');
        },
      );

      _trackingState = LocationTrackingState.tracking;
      debugPrint('Real-time location tracking started for trip $tripId');

      // Start heartbeat to periodically send last known if no movement
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            final locationData = {
              'type': 'location-update',
              'userId': userId,
              'tripId': tripId,
              'userRole': userRole,
              'latitude': last.latitude,
              'longitude': last.longitude,
              'accuracy': last.accuracy,
              'speed': last.speed,
              'heading': last.heading,
              'timestamp': DateTime.now().toIso8601String(),
            };
            _userLocations[userId] = locationData;
            onLocationUpdate(locationData);
            _sendLocationUpdate(userId, tripId, userRole, last);
          }
        } catch (e) {
          // ignore heartbeat errors
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('Failed to start real-time location tracking: $e');
      onError('Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop real-time location tracking
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    await _websocketSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _trackingState = LocationTrackingState.stopped;
    _userLocations.clear();
    debugPrint('Real-time location tracking stopped');
  }

  /// Send location update to server via WebSocket
  void _sendLocationUpdate(int userId, int tripId, String userRole, Position position) {
    try {
      // Send as simple location data that backend expects
      final locationData = {
        'type': 'location-update',
        'userId': userId,
        'tripId': tripId,
        'userRole': userRole,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send directly as location update (raw WebSocket)
      WebSocketService.instance.sendMessage(locationData);

      debugPrint('Sent location update: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Failed to send location update: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message, int tripId, int currentUserId) {
    try {
      // Check if this is a location update for our trip (allow missing type if fields exist)
      final isLocation = (message['type'] == 'location-update') ||
          (message['userId'] != null && message['latitude'] != null && message['longitude'] != null);
      if (isLocation && 
          message['tripId'] != null && 
          message['tripId'].toString() == tripId.toString()) {
        
        final userId = message['userId'];
        
        // Don't process our own updates
        if (userId.toString() != currentUserId.toString()) {
          // Ensure timestamp exists
          message['timestamp'] = message['timestamp'] ?? DateTime.now().toIso8601String();
          // Update the user's location in cache
          _userLocations[userId] = message;
          
          // Notify listeners
          if (onLocationUpdate != null) {
            onLocationUpdate!(message);
          }
          
          debugPrint('Received location update from user $userId');
        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Get cached location for a specific user
  Map<String, dynamic>? getUserLocation(int userId) {
    return _userLocations[userId];
  }

  /// Get all cached locations
  Map<int, Map<String, dynamic>> getAllLocations() {
    return Map.unmodifiable(_userLocations);
  }

  /// Check if a user is currently being tracked
  bool hasLocationForUser(int userId) {
    return _userLocations.containsKey(userId);
  }

  /// Calculate distance between two coordinates
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

/// Enum for tracking state
enum LocationTrackingState {
  stopped,
  starting,
  tracking,
  error,
}

