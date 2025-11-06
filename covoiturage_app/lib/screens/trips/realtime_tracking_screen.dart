import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/trip_service.dart';
import '../../services/websocket_service.dart';
import '../rating/rating_screen.dart';
import 'package:provider/provider.dart';
import '../../services/realtime_location_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeTrackingScreen extends StatefulWidget {
  final int tripId;
  final String userRole; // "DRIVER" or "PASSENGER"
  final List<Map<String, dynamic>> participants; // Other participants to track
  final Map<String, dynamic>? pickupPoint;
  final List<Map<String, dynamic>>? waypoints; // Ordered waypoints after current user location

  const RealtimeTrackingScreen({
    super.key,
    required this.tripId,
    required this.userRole,
    required this.participants,
    this.pickupPoint,
    this.waypoints,
  });

  @override
  State<RealtimeTrackingScreen> createState() => _RealtimeTrackingScreenState();
}

class _RealtimeTrackingScreenState extends State<RealtimeTrackingScreen> {
  final RealtimeLocationService _locationService = RealtimeLocationService();
  MapController? _mapController;
  
  List<Marker> _markers = [];
  List<CircleMarker> _circles = [];
  List<Polyline> _polylines = [];
  Polyline? _polylineToPickup; // current -> pickup
  Polyline? _polylinePickupToArrival; // pickup -> arrival
  Polyline? _polylineCurrentToArrival; // current -> arrival (for driver after passing pickup)
  LatLng? _arrivalTarget;
  LatLng? _pickupTarget;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  bool _endPromptShown = false;
  bool _pickupPromptShown = false;
  bool _nearPickup = false;
  
  // Default location (Tunis, Tunisia)
  static const LatLng _defaultLocation = LatLng(36.8065, 10.1815);
  LatLng _center = _defaultLocation;

  int? _userId;
  bool _isTracking = false;
  String? _errorMessage;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadTripArrivalPoint();
    // Listen for trip completion notifications (for passengers)
    _wsSub = WebSocketService.instance.messageStream.listen((message) {
      try {
        if (message['type'] == 'trip-completed' &&
            message['tripId'] != null &&
            message['tripId'].toString() == widget.tripId.toString()) {
          if (widget.userRole == 'PASSENGER' && mounted) {
            _promptPassengerRating();
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadTripArrivalPoint() async {
    try {
      final service = TripService();
      final tripDetails = await service.getTripDetails(widget.tripId);
      final points = tripDetails['points'] as List<dynamic>? ?? [];
      
      // Find END point (arrival) and PICKUP/START point
      for (final point in points) {
        final pointType = point['pointType']?.toString().toUpperCase();
        final lat = point['latitude'] as num?;
        final lon = point['longitude'] as num?;
        
        if (lat != null && lon != null) {
          if (pointType == 'END') {
            _arrivalTarget = LatLng(lat.toDouble(), lon.toDouble());
          } else if ((pointType == 'PICKUP' || pointType == 'START') && _pickupTarget == null) {
            // Only set pickup target if not already set from widget.pickupPoint
            if (widget.pickupPoint == null) {
              _pickupTarget = LatLng(lat.toDouble(), lon.toDouble());
            }
          }
        }
      }
      
      // If pickup point is provided in widget, use it
      if (widget.pickupPoint != null) {
        final lat = widget.pickupPoint!['latitude'] as num?;
        final lon = widget.pickupPoint!['longitude'] as num?;
        if (lat != null && lon != null) {
          _pickupTarget = LatLng(lat.toDouble(), lon.toDouble());
        }
      }
      
      // If arrival not found in GPS points, check last waypoint but ensure it's different from pickup
      if (_arrivalTarget == null && widget.waypoints != null && widget.waypoints!.isNotEmpty && _pickupTarget != null) {
        final last = widget.waypoints!.last;
        final lat = last['latitude'] as num?;
        final lon = last['longitude'] as num?;
        if (lat != null && lon != null) {
          // Check if last waypoint is different from pickup (more than 100m away)
          final distToPickup = _locationService.calculateDistance(
            _pickupTarget!.latitude,
            _pickupTarget!.longitude,
            lat.toDouble(),
            lon.toDouble(),
          );
          if (distToPickup > 100.0) {
            // Last waypoint is far enough from pickup, use it as arrival
            _arrivalTarget = LatLng(lat.toDouble(), lon.toDouble());
            debugPrint('DEBUG: Using last waypoint as arrival (${distToPickup}m from pickup): ${_arrivalTarget!.latitude}, ${_arrivalTarget!.longitude}');
          } else {
            debugPrint('DEBUG: Last waypoint is too close to pickup ($distToPickup m), skipping it - will geocode arrival city');
          }
        }
      }
      
      // If still no arrival target, geocode the arrival city name from trip details
      if (_arrivalTarget == null) {
        final arrivalCity = tripDetails['arrivalCity'] as String?;
        debugPrint('DEBUG: No END point found. Arrival city from trip: $arrivalCity');
        if (arrivalCity != null && arrivalCity.isNotEmpty) {
          debugPrint('DEBUG: Attempting to geocode arrival city: $arrivalCity');
          final coords = await _geocodeCity(arrivalCity);
          if (coords != null) {
            _arrivalTarget = LatLng(coords.$1, coords.$2);
            debugPrint('DEBUG: Successfully geocoded arrival city to: ${_arrivalTarget!.latitude}, ${_arrivalTarget!.longitude}');
          } else {
            debugPrint('DEBUG: Failed to geocode arrival city: $arrivalCity');
          }
        } else {
          debugPrint('DEBUG: Arrival city is null or empty');
        }
      } else {
        debugPrint('DEBUG: Arrival target already set from END point or waypoints: ${_arrivalTarget!.latitude}, ${_arrivalTarget!.longitude}');
      }
      
      debugPrint('DEBUG: Arrival target loaded: ${_arrivalTarget?.latitude}, ${_arrivalTarget?.longitude}');
      debugPrint('DEBUG: Pickup target loaded: ${_pickupTarget?.latitude}, ${_pickupTarget?.longitude}');
      
      if (mounted) {
        setState(() {});
        // Trigger route update when arrival point is loaded (outside setState since it's async)
        _updateRoute();
      }
    } catch (e) {
      debugPrint('Error loading trip arrival point: $e');
    }
  }

  Future<void> _initializeTracking(BuildContext context) async {
    // Get current user ID from auth provider via context
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.user?['id'] as int?;

    if (_userId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in';
        });
      }
      return;
    }

    // Start tracking
    final success = await _locationService.startTracking(
      userId: _userId!,
      tripId: widget.tripId,
      userRole: widget.userRole,
      onLocationUpdate: (locationData) {
        if (mounted) {
          setState(() {
            _updateMarkers();
            _updateMapCenter();
            _updateRoute();
          });
          // Check pickup proximity for both driver and passenger
          if (widget.userRole == 'DRIVER') {
            _maybePromptNearPickup();
            // Only check for end trip if we've passed pickup (or no pickup exists)
            // Don't check when near pickup - wait until we're closer to arrival
            final all = _locationService.getAllLocations();
            final me = _userId != null ? all[_userId] : null;
            bool pastPickup = false;
            
            if (me != null && me['latitude'] != null && _pickupTarget != null && _arrivalTarget != null) {
              final distToPickup = _locationService.calculateDistance(
                (me['latitude'] as num).toDouble(),
                (me['longitude'] as num).toDouble(),
                _pickupTarget!.latitude,
                _pickupTarget!.longitude,
              );
              final distToArrival = _locationService.calculateDistance(
                (me['latitude'] as num).toDouble(),
                (me['longitude'] as num).toDouble(),
                _arrivalTarget!.latitude,
                _arrivalTarget!.longitude,
              );
              // Past pickup if closer to arrival than pickup
              pastPickup = distToArrival < distToPickup;
            } else if (_pickupTarget == null) {
              // No pickup point, so we can check end trip
              pastPickup = true;
            }
            
            if (pastPickup) {
              _maybePromptEndTrip();
            }
          } else if (widget.userRole == 'PASSENGER') {
            // For passengers, also show pickup proximity message
            _maybePromptNearPickup();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isTracking = success;
        if (!success && _errorMessage == null) {
          _errorMessage = 'Failed to start tracking';
        }
      });
    }
  }

  void _updateMapCenter() {
    // Center map on current user's location or average of all participants
    final allLocations = _locationService.getAllLocations();
    
    if (allLocations.isNotEmpty) {
      // If we have other participants, center on average location
      double totalLat = 0, totalLon = 0;
      int count = 0;
      
      allLocations.values.forEach((loc) {
        if (loc['latitude'] != null && loc['longitude'] != null) {
          totalLat += loc['latitude'] as double;
          totalLon += loc['longitude'] as double;
          count++;
        }
      });
      
      if (count > 0) {
        _center = LatLng(totalLat / count, totalLon / count);
        if (_mapController != null) {
          _mapController!.move(_center, 13.0);
        }
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    final allLocations = _locationService.getAllLocations();
    
    debugPrint('DEBUG: _updateMarkers called');
    debugPrint('DEBUG: userRole: ${widget.userRole}, userId: $_userId');
    debugPrint('DEBUG: participants count: ${widget.participants.length}');
    debugPrint('DEBUG: participants: ${widget.participants.map((p) => '${p['id']}: ${p['firstName']}').toList()}');
    debugPrint('DEBUG: allLocations keys: ${allLocations.keys.toList()}');

    // Add pickup point marker
    if (widget.pickupPoint != null) {
      _markers.add(
        Marker(
          width: 60.0,
          height: 70.0,
          point: LatLng(
            widget.pickupPoint!['latitude'] as double,
            widget.pickupPoint!['longitude'] as double,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pickup',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add current user's own location marker
    if (_userId != null && allLocations.containsKey(_userId)) {
      final currentUserLoc = allLocations[_userId];
      if (currentUserLoc != null && currentUserLoc['latitude'] != null) {
        _markers.add(
          Marker(
            width: 60.0,
            height: 70.0,
            point: LatLng(
              currentUserLoc['latitude'] as double,
              currentUserLoc['longitude'] as double,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.userRole == 'DRIVER' ? Icons.directions_car : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        );
        debugPrint('DEBUG: Added "You" marker for user ID: $_userId');
      }
    }

    // Add passenger/other markers (participants, excluding current user)
    for (var participant in widget.participants) {
      final participantId = participant['id'] as int?;
      // Skip if this is the current user (we already added their marker above)
      if (participantId != null && participantId != _userId && allLocations.containsKey(participantId)) {
        final loc = allLocations[participantId]!;
        if (loc['latitude'] != null) {
          final participantFirstName = participant['firstName'] ?? 'Passenger';
          debugPrint('Adding marker for participant: $participantFirstName (ID: $participantId)');
          
          _markers.add(
            Marker(
              width: 60.0,
              height: 70.0,
              point: LatLng(
                loc['latitude'] as double,
                loc['longitude'] as double,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.userRole == 'DRIVER' ? Colors.orange : Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.userRole == 'DRIVER' ? Icons.person : Icons.directions_car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.userRole == 'DRIVER' ? Colors.orange.shade700 : Colors.purple.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.userRole == 'DRIVER' 
                          ? participantFirstName 
                          : 'Driver',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    // Also add any other tracked users not in participants (fallback)
    final participantIds = widget.participants.map((p) => p['id']).toSet();
    for (final entry in allLocations.entries) {
      final uid = entry.key;
      if (uid == _userId) continue;
      if (participantIds.contains(uid)) continue;
      final loc = entry.value;
      if (loc['latitude'] == null) continue;
      _markers.add(
        Marker(
          width: 60.0,
          height: 70.0,
          point: LatLng(
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.userRole == 'DRIVER' ? Colors.orange : Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.userRole == 'DRIVER' ? Colors.orange.shade700 : Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.userRole == 'DRIVER' ? 'Passenger' : 'Driver',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add pickup area circle
    if (widget.pickupPoint != null) {
      _circles.clear();
      _circles.add(
        CircleMarker(
          point: LatLng(
            widget.pickupPoint!['latitude'] as double,
            widget.pickupPoint!['longitude'] as double,
          ),
          radius: 2000.0, // 2km radius (matches detection radius)
          useRadiusInMeter: true,
          color: Colors.green.withOpacity(0.2),
          borderColor: Colors.green,
          borderStrokeWidth: 2,
        ),
      );
    }
    
    debugPrint('DEBUG: Total markers added: ${_markers.length}');
    debugPrint('DEBUG: All locations cache: $allLocations');
  }

  Future<void> _updateRoute() async {
    try {
      // Build using current location, pickup and arrival; hide current->pickup once near pickup
      final allLocations = _locationService.getAllLocations();
      final current = _userId != null ? allLocations[_userId] : null;
      if (current == null || current['latitude'] == null) {
        debugPrint('DEBUG: Cannot update route - no current location');
        return;
      }

      final LatLng currentLL = LatLng((current['latitude'] as num).toDouble(), (current['longitude'] as num).toDouble());
      debugPrint('DEBUG: Updating route - current: ${currentLL.latitude}, ${currentLL.longitude}');
      debugPrint('DEBUG: Arrival target: ${_arrivalTarget?.latitude}, ${_arrivalTarget?.longitude}');
      debugPrint('DEBUG: Pickup target: ${_pickupTarget?.latitude}, ${_pickupTarget?.longitude}');
      debugPrint('DEBUG: Near pickup: $_nearPickup');

      // Use arrival target from trip GPS points (END type), fallback to waypoints
      LatLng? arrivalLL = _arrivalTarget;
      if (arrivalLL == null && widget.waypoints != null && widget.waypoints!.isNotEmpty) {
        final last = widget.waypoints!.last;
        final lat = last['latitude'] as double?;
        final lon = last['longitude'] as double?;
        if (lat != null && lon != null) {
          arrivalLL = LatLng(lat, lon);
        }
      }

      // Use pickup target from widget or GPS points
      LatLng? pickupLL = _pickupTarget;
      if (pickupLL == null && widget.pickupPoint != null) {
        final lat = widget.pickupPoint!['latitude'] as double?;
        final lon = widget.pickupPoint!['longitude'] as double?;
        if (lat != null && lon != null) {
          pickupLL = LatLng(lat, lon);
          _pickupTarget = pickupLL;
        }
      }

      // Determine proximity to pickup (2 km)
      if (pickupLL != null) {
        final d = _locationService.calculateDistance(
          currentLL.latitude, currentLL.longitude, pickupLL.latitude, pickupLL.longitude,
        );
        _nearPickup = d <= 2000.0; // 2km radius
      } else {
        _nearPickup = true; // no pickup -> consider passed
      }
      
      // Update pickup target if needed
      if (pickupLL != null && _pickupTarget == null) {
        _pickupTarget = pickupLL;
      }
      
      // Update arrival target if needed
      if (arrivalLL != null && _arrivalTarget == null) {
        _arrivalTarget = arrivalLL;
      }

      // Determine if near pickup (within 2km circle) - this triggers route switch to arrival
      // Use _nearPickup which is already calculated above (2km radius)
      bool showRouteToArrival = _nearPickup; // If within pickup circle, show route to arrival
      if (pickupLL == null) {
        showRouteToArrival = true; // No pickup point, so show route to arrival directly
      }

      Polyline? toPickup;
      Polyline? pickupToArrival;
      Polyline? currentToArrival;

      // For DRIVER: Show route to pickup first, then switch to route to arrival when in pickup circle
      if (widget.userRole == 'DRIVER') {
        if (pickupLL != null && !showRouteToArrival) {
          // Before entering pickup circle: show route to pickup
          debugPrint('DEBUG: DRIVER - Showing route to pickup');
          final seg = await _fetchOsrmRoute([currentLL, pickupLL]);
          if (seg != null) {
            toPickup = Polyline(points: seg, color: Colors.orange, strokeWidth: 4);
            debugPrint('DEBUG: Route to pickup calculated: ${seg.length} points');
          } else {
            debugPrint('DEBUG: Failed to fetch route to pickup');
          }
        } else if (arrivalLL != null && showRouteToArrival) {
          // After entering pickup circle (or no pickup): show route from current to arrival
          debugPrint('DEBUG: DRIVER - Showing route to arrival (near pickup: $showRouteToArrival)');
          final seg = await _fetchOsrmRoute([currentLL, arrivalLL]);
          if (seg != null) {
            currentToArrival = Polyline(points: seg, color: Colors.blueAccent, strokeWidth: 4);
            debugPrint('DEBUG: Route to arrival calculated: ${seg.length} points');
          } else {
            debugPrint('DEBUG: Failed to fetch route to arrival');
          }
        } else {
          debugPrint('DEBUG: DRIVER - No route shown. arrivalLL: ${arrivalLL != null}, showRouteToArrival: $showRouteToArrival');
        }
      } 
      // For PASSENGER: Show route to pickup first, then switch to route to arrival when in pickup circle
      // Hide all routes when passenger is at arrival (within 20km)
      else if (widget.userRole == 'PASSENGER') {
        // Check if passenger is near arrival (within 20km) - if so, hide all routes
        bool nearArrival = false;
        if (arrivalLL != null) {
          final distToArrival = _locationService.calculateDistance(
            currentLL.latitude, currentLL.longitude, arrivalLL.latitude, arrivalLL.longitude,
          );
          nearArrival = distToArrival <= 20000.0; // 20km
        }
        
        if (!nearArrival) {
          // Only show routes if not at arrival
          if (pickupLL != null && !showRouteToArrival) {
            // Before entering pickup circle: show route to pickup point
            final segToPickup = await _fetchOsrmRoute([currentLL, pickupLL]);
            if (segToPickup != null) {
              toPickup = Polyline(points: segToPickup, color: Colors.orange, strokeWidth: 4);
            }
            // Also show route from pickup to arrival for reference
            if (arrivalLL != null) {
              final segPickupToArrival = await _fetchOsrmRoute([pickupLL, arrivalLL]);
              if (segPickupToArrival != null) {
                pickupToArrival = Polyline(points: segPickupToArrival, color: Colors.blueAccent, strokeWidth: 4);
              }
            }
          } else if (arrivalLL != null && showRouteToArrival) {
            // After entering pickup circle (or no pickup): show route from current position to arrival
            final seg = await _fetchOsrmRoute([currentLL, arrivalLL]);
            if (seg != null) {
              currentToArrival = Polyline(points: seg, color: Colors.blueAccent, strokeWidth: 4);
            }
          }
        } else {
          debugPrint('DEBUG: PASSENGER at arrival (within 20km), hiding all routes');
        }
      }

      if (!mounted) return;
      setState(() {
        // Store polylines in state
        _polylineToPickup = toPickup;
        _polylinePickupToArrival = pickupToArrival;
        _polylineCurrentToArrival = currentToArrival;
        
        // Build polylines list based on role
        _polylines = [];
        
        // For DRIVER: Show either route to pickup OR route to arrival (not both)
        if (widget.userRole == 'DRIVER') {
          if (_polylineCurrentToArrival != null) {
            // After passing pickup: show route from current position to arrival
            _polylines.add(_polylineCurrentToArrival!);
          } else if (_polylineToPickup != null) {
            // Before passing pickup: show route to pickup point
            _polylines.add(_polylineToPickup!);
          }
        }
        // For PASSENGER: Show route to pickup first, then switch to route to arrival after passing pickup
        else if (widget.userRole == 'PASSENGER') {
          if (_polylineCurrentToArrival != null) {
            // After passing pickup: show route from current position to arrival
            _polylines.add(_polylineCurrentToArrival!);
          } else {
            // Before passing pickup: show route to pickup and from pickup to arrival
            if (_polylineToPickup != null) _polylines.add(_polylineToPickup!);
            if (_polylinePickupToArrival != null) _polylines.add(_polylinePickupToArrival!);
          }
        }
      });
      // After route updates, re-check prompt condition
      if (widget.userRole == 'DRIVER') {
        _maybePromptEndTrip();
      }
    } catch (e) {
      debugPrint('Failed to update route: $e');
      debugPrint('DEBUG: Route update error stack: ${StackTrace.current}');
    }
  }

  // Simple city geocoding using Nominatim (OpenStreetMap)
  Future<(double, double)?> _geocodeCity(String city) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(city)}&format=json&limit=1');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'covoiturage_app/1.0 (contact@example.com)'
      }).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as List<dynamic>;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (_) {
      return null;
    }
  }

  // Fetch route from OSRM public server, geometry as GeoJSON
  Future<List<LatLng>?> _fetchOsrmRoute(List<LatLng> coords) async {
    try {
      // OSRM expects lon,lat; build path
      final parts = coords
          .map((c) => '${c.longitude.toStringAsFixed(6)},${c.latitude.toStringAsFixed(6)}')
          .join(';');
      final uri = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$parts?overview=full&geometries=geojson');
      debugPrint('DEBUG: Fetching OSRM route: $uri');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        debugPrint('OSRM error: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('DEBUG: No routes returned from OSRM');
        return null;
      }
      final geometry = routes.first['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null) {
        debugPrint('DEBUG: No coordinates in OSRM response');
        return null;
      }
      final routePoints = coordinates
          .map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
          .toList(growable: false);
      debugPrint('DEBUG: OSRM route fetched successfully: ${routePoints.length} points');
      return routePoints;
    } catch (e) {
      debugPrint('OSRM fetch failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _mapController?.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize tracking on first build
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeTracking(context);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: _isTracking ? null : () => _initializeTracking(context),
            tooltip: _isTracking ? 'Tracking Active' : 'Start Tracking',
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorState(context)
          : _isTracking
              ? _buildTrackingView()
              : _buildLoadingState(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _initializeTracking(context),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Starting real-time tracking...'),
        ],
      ),
    );
  }

  Widget _buildTrackingView() {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _center,
            zoom: 15.0,
            maxZoom: 18.0,
            minZoom: 5.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.covoiturage.covoiturage_app',
            ),
            if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  icon: widget.userRole == 'DRIVER' ? Icons.directions_car : Icons.person,
                  color: Colors.blue,
                  text: 'You',
                ),
                const SizedBox(height: 4),
                _buildLegendItem(
                  icon: widget.userRole == 'DRIVER' ? Icons.person : Icons.directions_car,
                  color: widget.userRole == 'DRIVER' ? Colors.orange : Colors.purple,
                  text: widget.userRole == 'DRIVER' ? 'Passenger' : 'Driver',
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
        
        // Zoom Controls
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
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
                // Zoom In Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_mapController == null) return;
                      final currentZoom = _mapController!.camera.zoom;
                      _mapController!.move(_center, currentZoom + 1);
                    },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 24),
                    ),
                  ),
                ),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                // Zoom Out Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_mapController == null) return;
                      final currentZoom = _mapController!.camera.zoom;
                      _mapController!.move(_center, currentZoom - 1);
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.remove, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // End Trip action (driver only)
        if (widget.userRole == 'DRIVER')
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _canEndTrip() ? _endTrip : null,
              icon: const Icon(Icons.flag),
              label: Text(_canEndTrip()
                  ? 'End Trip (arrival reached)'
                  : 'End Trip (get closer to arrival)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _canEndTrip() ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
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
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  bool _canEndTrip() {
    // Can only end trip if near arrival point, not pickup point
    if (_arrivalTarget == null) return false;
    
    final all = _locationService.getAllLocations();
    final me = _userId != null ? all[_userId] : null;
    if (me == null || me['latitude'] == null) return false;
    
    final currentLat = (me['latitude'] as num).toDouble();
    final currentLon = (me['longitude'] as num).toDouble();
    
    // Check distance to ARRIVAL point (not pickup)
    final distToArrival = _locationService.calculateDistance(
      currentLat,
      currentLon,
      _arrivalTarget!.latitude,
      _arrivalTarget!.longitude,
    );
    
    // If pickup exists, MUST be closer to arrival than pickup
    if (_pickupTarget != null) {
      final distToPickup = _locationService.calculateDistance(
        currentLat,
        currentLon,
        _pickupTarget!.latitude,
        _pickupTarget!.longitude,
      );
      
      // Must be closer to arrival than pickup (passed pickup point)
      if (distToArrival >= distToPickup) {
        return false; // Still closer to pickup than arrival
      }
    }
    
    // within 20 km radius of arrival ONLY
    return distToArrival <= 20000.0;
  }

  void _maybePromptNearPickup() {
    if (_pickupTarget == null) return;
    if (_pickupPromptShown) return;
    if (!_nearPickup) return;
    
    final all = _locationService.getAllLocations();
    final me = _userId != null ? all[_userId] : null;
    if (me == null || me['latitude'] == null) return;
    
    final dist = _locationService.calculateDistance(
      (me['latitude'] as num).toDouble(),
      (me['longitude'] as num).toDouble(),
      _pickupTarget!.latitude,
      _pickupTarget!.longitude,
    );
    
    // Show message when within 2km of pickup
    if (dist <= 2000.0 && !_pickupPromptShown) {
      _pickupPromptShown = true;
      if (!mounted) return;
      
      // Different message for driver vs passenger
      final message = widget.userRole == 'DRIVER'
          ? 'You are near the pickup point. Proceed to the arrival destination.'
          : 'You are at the pickup point. The trip will proceed to the arrival destination.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _maybePromptEndTrip() {
    if (_endPromptShown) return;
    if (!_canEndTrip()) return;
    _endPromptShown = true;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Arrival Nearby'),
        content: const Text('You are near the arrival. End the trip now?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endTrip();
            },
            child: const Text('End Trip'),
          ),
        ],
      ),
    ).then((_) {
      // Allow re-prompt if driver moves away and comes back later (optional)
      // Keep it shown-once per session by default
    });
  }

  Future<void> _endTrip() async {
    try {
      // First check if trip is ACTIVE
      final service = TripService();
      final tripDetails = await service.getTripDetails(widget.tripId);
      final tripStatus = tripDetails['status']?.toString().toUpperCase();
      
      if (tripStatus != 'ACTIVE') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip is not active. Current status: $tripStatus'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await service.completeTrip(widget.tripId);
      if (!mounted) return;

      // Notify others (passengers) via websocket
      if (!WebSocketService.instance.isConnected) {
        await WebSocketService.instance.connect();
      }
      WebSocketService.instance.sendMessage({
        'type': 'trip-completed',
        'tripId': widget.tripId,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Prompt driver to rate passengers one by one
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _promptDriverRating();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete trip: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _promptDriverRating({int currentIndex = 0}) {
    // If there are participants, they are passengers for driver
    final passengers = widget.participants;
    if (passengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip ended. No passengers to rate.'), backgroundColor: Colors.green),
      );
      return;
    }

    // Rate passengers one by one sequentially
    if (currentIndex < passengers.length) {
      final passenger = passengers[currentIndex];
      Navigator.of(context).push(
        MaterialPageRoute(
                  builder: (_) => FutureBuilder<Map<String, dynamic>>(
                    future: TripService().getTripDetails(widget.tripId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final tripDetails = snapshot.data ?? {'id': widget.tripId};
                      return RatingScreen(
                        trip: tripDetails,
                        userToRate: passenger,
                        ratingType: 'passenger',
                        onRatingComplete: () {
                          // After rating is complete, check if there are more passengers
                          if (currentIndex + 1 < passengers.length) {
                            // Navigate back and prompt for next passenger
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                _promptDriverRating(currentIndex: currentIndex + 1);
                              }
                            });
                          } else {
                            // All passengers rated, show success message
                            Navigator.of(context).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All passengers rated. Thank you!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              );
            }
          }

  Future<void> _promptPassengerRating() async {
    // Load full trip details for rating screen
    try {
      final service = TripService();
      final tripDetails = await service.getTripDetails(widget.tripId);
      
      // For passenger, participants list typically contains the driver
      Map<String, dynamic>? driver;
      if (widget.participants.isNotEmpty) {
        driver = widget.participants.first;
      }
      
      // If no driver in participants, try to get from trip details
      if (driver == null && tripDetails['driver'] != null) {
        driver = tripDetails['driver'] as Map<String, dynamic>;
      }
      
      if (driver == null) {
        debugPrint('DEBUG: No driver found for passenger rating');
        return;
      }

      if (!mounted) return;

      // One-time guards
      try {
        // 1) local flag - if rating submitted previously for this trip
        final prefs = await SharedPreferences.getInstance();
        final doneKey = 'driver_rating_done_trip_${widget.tripId}';
        final promptedKey = 'driver_rating_prompted_trip_${widget.tripId}';
        if (prefs.getBool(doneKey) == true) {
          debugPrint('DEBUG: Local flag indicates driver already rated for trip ${widget.tripId}, skipping');
          return;
        }
        if (prefs.getBool(promptedKey) == true) {
          debugPrint('DEBUG: Prompt already shown once for trip ${widget.tripId}, skipping');
          return;
        }
        // 2) server check - if rating exists, mark done and skip
        final api = ApiService.instance;
        final myRatings = await api.getUserRatings();
        final driverId = driver['id'] ?? driver['userId'] ?? driver['driverId'] ?? driver['conducteurId'];
        List<dynamic> ratingsList;
        if (myRatings is Map) {
          final data = (myRatings as Map)['data'];
          ratingsList = data is List ? List<dynamic>.from(data) : <dynamic>[];
        } else if (myRatings is List) {
          ratingsList = List<dynamic>.from(myRatings);
        } else {
          ratingsList = <dynamic>[];
        }
        final alreadyRated = ratingsList.whereType<Map>().any((r) => r['voyageId'] == widget.tripId && r['userId'] == driverId);
        if (alreadyRated) {
          await prefs.setBool(doneKey, true);
          debugPrint('DEBUG: Server indicates driver already rated for trip ${widget.tripId}, skipping');
          return;
        }
      } catch (e) {
        debugPrint('DEBUG: Could not check existing ratings, proceeding with popup: $e');
      }
      
      // Mark as prompted so we don't show the dialog repeatedly
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('driver_rating_prompted_trip_${widget.tripId}', true);
      } catch (_) {}

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Trip Completed'),
          content: const Text('Please rate your driver.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RatingScreen(
                      trip: tripDetails, // Pass full trip details instead of just id
                      userToRate: driver!,
                      ratingType: 'driver',
                      onRatingComplete: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('driver_rating_done_trip_${widget.tripId}', true);
                        } catch (_) {}
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
              child: const Text('Rate Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error prompting passenger rating: $e');
    }
  }
}

