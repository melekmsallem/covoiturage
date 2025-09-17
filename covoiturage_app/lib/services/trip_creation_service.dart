import 'api_service.dart';

class TripCreationService {
  static final TripCreationService _instance = TripCreationService._internal();
  factory TripCreationService() => _instance;
  TripCreationService._internal();

  final ApiService _apiService = ApiService.instance;

  /// Get form data for trip creation (cities, options, etc.)
  Future<Map<String, dynamic>> getFormData() async {
    try {
      final response = await _apiService.getDynamic('/trip-creation/form-data');
      return response;
    } catch (e) {
      throw Exception('Failed to load form data: $e');
    }
  }

  /// Validate trip creation request
  Future<Map<String, dynamic>> validateTripCreation(Map<String, dynamic> tripData) async {
    try {
      final response = await _apiService.post('/trip-creation/validate', tripData);
      return response;
    } catch (e) {
      throw Exception('Failed to validate trip: $e');
    }
  }

  /// Get trip estimation (distance, duration, etc.)
  Future<Map<String, dynamic>> estimateTrip(Map<String, dynamic> routeData) async {
    try {
      final response = await _apiService.post('/trip-creation/estimate', routeData);
      return response;
    } catch (e) {
      throw Exception('Failed to estimate trip: $e');
    }
  }

  /// Create a new trip
  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    try {
      final response = await _apiService.post('/trip-creation/create', tripData);
      return response;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }


  /// Helper method to format trip data for API
  Map<String, dynamic> formatTripData({
    required DateTime departureTime,
    required DateTime arrivalTime,
    required double pricePerSeat,
    required int maxSeats,
    required String departureCity,
    required String arrivalCity,
    String? description,
    List<int>? optionIds,
    Map<String, dynamic>? departurePoint,
    Map<String, dynamic>? arrivalPoint,
  }) {
    final tripData = {
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'pricePerSeat': pricePerSeat,
      'maxSeats': maxSeats,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
    };

    if (description != null && description.isNotEmpty) {
      tripData['description'] = description;
    }

    if (optionIds != null && optionIds.isNotEmpty) {
      tripData['optionIds'] = optionIds;
    }

    if (departurePoint != null) {
      tripData['departurePoint'] = {
        'latitude': departurePoint['latitude'],
        'longitude': departurePoint['longitude'],
        'address': departureCity,
      };
    }

    if (arrivalPoint != null) {
      tripData['arrivalPoint'] = {
        'latitude': arrivalPoint['latitude'],
        'longitude': arrivalPoint['longitude'],
        'address': arrivalCity,
      };
    }

    return tripData;
  }

  /// Helper method to format route data for estimation
  Map<String, dynamic> formatRouteData({
    required String departureAddress,
    required String arrivalAddress,
    List<String>? waypoints,
  }) {
    final routeData = {
      'departureAddress': departureAddress,
      'arrivalAddress': arrivalAddress,
    };

    if (waypoints != null && waypoints.isNotEmpty) {
      routeData['waypoints'] = waypoints.join(',');
    }

    return routeData;
  }
}
