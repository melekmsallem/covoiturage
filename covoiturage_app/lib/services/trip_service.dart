import 'api_service.dart';

class TripService {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final ApiService _apiService = ApiService.instance;

  /// Search trips with advanced filtering and pagination
  Future<Map<String, dynamic>> searchTrips(Map<String, dynamic> searchRequest, {int page = 0, int size = 10}) async {
    try {
      final response = await _apiService.post('/trips/search?page=$page&size=$size&sort=departureTime,asc', searchRequest);
      return response;
    } catch (e) {
      throw Exception('Failed to search trips: $e');
    }
  }

  /// Get available trips (public endpoint)
  Future<Map<String, dynamic>> getAvailableTrips({
    String? departureCity,
    String? arrivalCity,
    String? date,
    int? minPrice,
    int? maxPrice,
    int? seats,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (departureCity != null) queryParams['departureCity'] = departureCity;
      if (arrivalCity != null) queryParams['arrivalCity'] = arrivalCity;
      if (date != null) queryParams['date'] = date;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (seats != null) queryParams['seats'] = seats.toString();
      queryParams['page'] = page.toString();
      queryParams['size'] = size.toString();

      final qp = queryParams.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final path = qp.isEmpty ? '/trips/available' : '/trips/available?' + qp;
      final response = await _apiService.getDynamic(path);
      return response;
    } catch (e) {
      throw Exception('Failed to get available trips: $e');
    }
  }

  /// Get trip details by ID
  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/trips/$tripId');
      return response;
    } catch (e) {
      throw Exception('Failed to get trip details: $e');
    }
  }

  /// Get trip by ID (alias for getTripDetails)
  Future<Map<String, dynamic>> getTripById(int tripId) async {
    return getTripDetails(tripId);
  }

  /// Update a trip (driver only)
  Future<Map<String, dynamic>> updateTrip(int tripId, Map<String, dynamic> updateRequest) async {
    try {
      final response = await _apiService.put('/trips/$tripId', updateRequest);
      return response;
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  /// Book a trip
  Future<Map<String, dynamic>> bookTrip(int tripId, Map<String, dynamic> bookingRequest) async {
    try {
      // Add tripId to the booking request
      final requestWithTripId = {
        ...bookingRequest,
        'tripId': tripId,
      };
      final response = await _apiService.post('/bookings', requestWithTripId);
      return response;
    } catch (e) {
      throw Exception('Failed to book trip: $e');
    }
  }

  /// Get user's bookings with pagination
  Future<Map<String, dynamic>> getMyBookings({int page = 0, int size = 10}) async {
    try {
      final response = await _apiService.getDynamic('/bookings/my-bookings?page=$page&size=$size&sort=reservationDate,desc');
      // Response should be {data, page, size, totalPages, totalElements}
      if (response is Map<String, dynamic>) {
        return response;
      }
      // Fallback if still returning array
      return {'data': response, 'page': 0, 'totalPages': 1, 'totalElements': (response as List).length};
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  /// Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/cancel', {});
      return response;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get driver's trips
  Future<List<dynamic>> getMyTrips() async {
    try {
      final response = await _apiService.getDynamic('/trips/my-trips');
      // Extract the 'data' field from the response
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List<dynamic>;
      }
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get my trips: $e');
    }
  }

  /// Start a trip (driver only)
  Future<Map<String, dynamic>> startTrip(int tripId) async {
    try {
      final response = await _apiService.post('/trips/$tripId/start', {});
      return response;
    } catch (e) {
      throw Exception('Failed to start trip: $e');
    }
  }

  /// Complete a trip (driver only)
  Future<Map<String, dynamic>> completeTrip(int tripId) async {
    try {
      final response = await _apiService.post('/trips/$tripId/complete', {});
      return response;
    } catch (e) {
      throw Exception('Failed to complete trip: $e');
    }
  }

  /// Cancel a trip (driver only)
  Future<Map<String, dynamic>> cancelTrip(int tripId) async {
    try {
      final response = await _apiService.post('/trips/$tripId/cancel', {});
      return response;
    } catch (e) {
      throw Exception('Failed to cancel trip: $e');
    }
  }

  /// Create a new trip (driver only)
  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    try {
      final response = await _apiService.post('/trip-creation/create', tripData);
      return response;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  /// Get trip bookings (driver only)
  Future<List<dynamic>> getTripBookings(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/trips/$tripId/bookings');
      // Extract the 'data' field from the response if it exists
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List<dynamic>;
      }
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get trip bookings: $e');
    }
  }

  /// Confirm a booking (driver only)
  Future<Map<String, dynamic>> confirmBooking(int bookingId) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/confirm', {});
      return response;
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }


  /// Decline a booking (driver only)
  Future<Map<String, dynamic>> declineBooking(int bookingId) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/decline', {});
      return response;
    } catch (e) {
      throw Exception('Failed to decline booking: $e');
    }
  }

  /// Get driver's bookings (bookings for trips created by the driver)
  Future<List<dynamic>> getDriverBookings() async {
    try {
      final response = await _apiService.getDynamic('/bookings/my-trip-bookings');
      // Extract the 'data' field from the response if it exists
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List<dynamic>;
      }
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get driver bookings: $e');
    }
  }

  /// Set passenger pickup point for individual pickup trips
  Future<Map<String, dynamic>> setPickupPoint({
    required int bookingId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.post('/bookings/$bookingId/pickup-point', {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to set pickup point: $e');
    }
  }

  /// Get trip pickup points (only for confirmed bookings or driver)
  Future<List<dynamic>> getTripPickupPoints(int tripId) async {
    try {
      final response = await _apiService.getDynamic('/bookings/trip/$tripId/pickup-points');
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get pickup points: $e');
    }
  }

  /// Helper method to format booking request
  Map<String, dynamic> formatBookingRequest({
    required int numberOfSeats,
    String? notes,
    Map<String, dynamic>? pickupPoint,
  }) {
    return {
      'numberOfSeats': numberOfSeats,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (pickupPoint != null) ...{
        'pickupAddress': pickupPoint['address'],
        'pickupLatitude': pickupPoint['latitude'],
        'pickupLongitude': pickupPoint['longitude'],
      },
    };
  }
}