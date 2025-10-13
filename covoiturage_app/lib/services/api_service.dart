import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use localhost for web (same machine browser), LAN IP for devices
  static final String baseUrl = kIsWeb
      ? 'http://localhost:8081/api'
      : 'http://192.168.1.14:8081/api';
  static ApiService? _instance;
  static String? _inMemoryToken;
  
  ApiService._internal();
  
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Allow setting token in-memory to avoid timing issues with SharedPreferences on web
  static void setToken(String? token) {
    _inMemoryToken = token;
  }

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_token');
    final token = _inMemoryToken ?? stored;
    
    // Always include Authorization when token exists
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';
      
      debugPrint('GET request to: $url');
      debugPrint('Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // 404 means resource not found, which is normal for some endpoints
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      } else {
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic GET request that can return arrays or objects
  Future<dynamic> getDynamic(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('POST request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('PUT request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('DELETE request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Trip-related methods
  Future<List<dynamic>> getAvailableTrips() async {
    final response = await getDynamic('/trips/available');
    // The API returns the array directly
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> searchTrips(Map<String, dynamic> searchParams) async {
    final response = await post('/trips/search', searchParams);
    return response['data'] ?? [];
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    return await post('/trips', tripData);
  }

  Future<Map<String, dynamic>> getTripById(int tripId) async {
    return await get('/trips/$tripId');
  }

  Future<Map<String, dynamic>> updateTrip(int tripId, Map<String, dynamic> tripData) async {
    return await put('/trips/$tripId', tripData);
  }

  Future<Map<String, dynamic>> cancelTrip(int tripId) async {
    return await post('/trips/$tripId/cancel', {});
  }

  // Booking-related methods
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await post('/bookings', bookingData);
  }

  Future<List<dynamic>> getUserBookings() async {
    final response = await get('/bookings/my-bookings');
    return response['data'] ?? [];
  }

  Future<Map<String, dynamic>> getBookingById(int bookingId) async {
    return await get('/bookings/$bookingId');
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    return await post('/bookings/$bookingId/cancel', {});
  }

  // Payment-related methods
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData) async {
    return await post('/payments', paymentData);
  }

  Future<Map<String, dynamic>> processPayment(int paymentId, Map<String, dynamic> paymentData) async {
    return await post('/payments/$paymentId/process', paymentData);
  }

  Future<Map<String, dynamic>> getPaymentByReservation(int reservationId) async {
    return await get('/payments/reservation/$reservationId');
  }

  Future<List<dynamic>> getUserPayments() async {
    final response = await getDynamic('/payments/my-payments');
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<Map<String, dynamic>> getPaymentById(int paymentId) async {
    return await get('/payments/$paymentId');
  }

  // Rating-related methods
  Future<Map<String, dynamic>> createRating(Map<String, dynamic> ratingData) async {
    return await post('/ratings', ratingData);
  }

  Future<List<dynamic>> getUserRatings() async {
    final response = await get('/ratings/my-ratings');
    return response['data'] ?? [];
  }

  Future<Map<String, dynamic>> getRatingStatistics(int userId) async {
    return await get('/ratings/statistics/$userId');
  }

  // Notification-related methods
  Future<List<dynamic>> getNotifications() async {
    final response = await get('/notifications');
    return response['data'] ?? [];
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    return await post('/notifications/$notificationId/read', {});
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await post('/notifications/mark-all-read', {});
  }

  // Options and Cities
  Future<List<dynamic>> getTripOptions() async {
    final response = await getDynamic('/options');
    // The API returns the array directly
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<List<dynamic>> getCities() async {
    // Admin endpoint returns full list of cities
    final response = await getDynamic('/admin/cities');
    // The API returns the array directly
    if (response is List) {
      return response;
    }
    return [];
  }
}

