import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Resolve base URL at runtime with fallbacks
  static String? _resolvedBaseUrl; // cached once detected
  static const String _overrideKey = 'api_base_override';
  static const List<String> _mobileCandidates = [
    'http://192.168.1.35:8081/api', // Current Wi-Fi IP for dev machine
    'http://172.20.10.9:8081/api',  // Phone hotspot IP (update if hotspot changes)
    'http://192.168.1.17:8081/api', // Legacy LAN IP example (adjust if needed)
    'http://10.0.2.2:8081/api',     // Android emulator to host
    'http://127.0.0.1:8081/api',    // Real device with `adb reverse tcp:8081 tcp:8081`
    'http://localhost:8081/api',    // Fallback for some environments
  ];
  static const String _webDefault = 'http://localhost:8081/api';
  static ApiService? _instance;
  static String? _inMemoryToken;
  
  ApiService._internal();
  
  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Determine which base URL to use (cached after first success)
  static Future<String> _getBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      debugPrint('Using cached API base: $_resolvedBaseUrl');
      return _resolvedBaseUrl!;
    }
    if (kIsWeb) {
      _resolvedBaseUrl = _webDefault;
      return _resolvedBaseUrl!;
    }

    debugPrint('Starting backend detection...');
    // 1) Try manual override from SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString(_overrideKey);
      if (override != null && override.trim().isNotEmpty) {
        final trimmed = override.trim().replaceAll(RegExp(r"/+$"), '');
        final candidate = trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
        debugPrint('Manual API override present: $candidate');
        final uri = Uri.parse('$candidate/simple/health');
        final resp = await http
            .get(uri, headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          debugPrint('✅ Using manual override API base: $candidate');
          return _resolvedBaseUrl!;
        } else {
          debugPrint('⚠️ Override responded with status ${resp.statusCode}, falling back to autodetect');
        }
      }
    } catch (e) {
      debugPrint('Override check failed: $e');
    }
    // Try candidates quickly (public endpoint) until one responds
    for (var i = 0; i < _mobileCandidates.length; i++) {
      final candidate = _mobileCandidates[i];
      try {
        debugPrint('Testing backend URL: $candidate');
        // Use a lightweight health endpoint available in backend
        final uri = Uri.parse('$candidate/simple/health');
        final resp = await http
            .get(uri, headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 10));
        debugPrint('Response from $candidate: Status ${resp.statusCode}');
        if (resp.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          debugPrint('✅ Resolved API base: $candidate');
          return _resolvedBaseUrl!;
        }
      } catch (e) {
        debugPrint('❌ Failed to connect to $candidate: $e');
        // try next
      }
    }

    // Final fallback to LAN default even if probe failed
    _resolvedBaseUrl = _mobileCandidates.first;
    debugPrint('⚠️ Using fallback API base: $_resolvedBaseUrl (probe failed)');
    return _resolvedBaseUrl!;
  }

  // Expose resolved base URL for other services that build absolute URLs
  static Future<String> getResolvedBaseUrl() async {
    return _getBaseUrl();
  }

  // Reset cached base URL to force re-detection
  static void resetBaseUrl() {
    _resolvedBaseUrl = null;
    debugPrint('Base URL cache reset - will re-detect on next request');
  }

  // Allow setting token in-memory to avoid timing issues with SharedPreferences on web
  static void setToken(String? token) {
    _inMemoryToken = token;
  }

  // Get authorization headers
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('auth_token');
    // Prioritize in-memory token over stored token
    final token = _inMemoryToken ?? stored;
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Only include Authorization when explicitly requested and token exists
    if (includeAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('Using token for request: ${token.substring(0, 20)}...');
    } else {
      debugPrint('No token available for request');
    }
    
    return headers;
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final base = await _getBaseUrl();
      final url = '$base$endpoint';
      
      debugPrint('GET request to: $url');
      debugPrint('Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('GET response status: ${response.statusCode}');
      debugPrint('GET response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // 404 means resource not found, which is normal for some endpoints
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      } else {
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('GET request error: $e');
      final base = await _getBaseUrl();
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to backend at $base. Please check if the backend is running and your device is on the same network.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Generic GET request that can return arrays or objects
  Future<dynamic> getDynamic(String endpoint) async {
    try {
      final base = await _getBaseUrl();
      final response = await http.get(
        Uri.parse('$base$endpoint'),
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

  // Generic GET request without authentication (for public endpoints)
  Future<dynamic> getPublic(String endpoint) async {
    try {
      final base = await _getBaseUrl();
      final url = '$base$endpoint';
      debugPrint('Public GET request to: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: false), // Explicitly no auth
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Public GET request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final base = await _getBaseUrl();
      final url = '$base$endpoint';
      debugPrint('POST request to: $url');
      debugPrint('Request data: ${jsonEncode(data)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      debugPrint('POST response status: ${response.statusCode}');
      debugPrint('POST response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('POST request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('POST request error: $e');
      final base = await _getBaseUrl();
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to backend at $base. Please check if the backend is running and your device is on the same network.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Public POST request (no authentication)
  Future<Map<String, dynamic>> postPublic(String endpoint, Map<String, dynamic> data) async {
    try {
      final base = await _getBaseUrl();
      final url = '$base$endpoint';
      debugPrint('Public POST request to: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode(data),
      );

      debugPrint('Public POST response status: ${response.statusCode}');
      debugPrint('Public POST response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Public POST request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Public POST request failed: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final base = await _getBaseUrl();
      final url = '$base$endpoint';
      final headers = await _getHeaders();
      
      debugPrint('PUT request to: $url');
      debugPrint('PUT request headers: $headers');
      debugPrint('PUT request body: ${jsonEncode(data)}');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      debugPrint('PUT response status: ${response.statusCode}');
      debugPrint('PUT response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again. Response: ${response.body}');
      } else {
        throw Exception('PUT request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('PUT request error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        final base = await _getBaseUrl();
        throw Exception('Cannot connect to backend at $base. Please check if the backend is running and your device is on the same network.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final base = await _getBaseUrl();
      final response = await http.delete(
        Uri.parse('$base$endpoint'),
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

  Future<bool> canRateTrip(int tripId) async {
    try {
      final response = await get('/ratings/can-rate/$tripId');
      final data = response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response);
      final canRate = data['canRate'];
      if (canRate is bool) return canRate;
      if (canRate is String) return canRate.toLowerCase() == 'true';
      return false;
    } catch (_) {
      return false;
    }
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
    // Use the regular cities endpoint instead of admin endpoint
    final response = await getDynamic('/cities');
    // The API returns the array directly
    if (response is List) {
      return response;
    }
    return [];
  }

  // Report a user
  Future<Map<String, dynamic>> submitReport({
    required int reportedUserId,
    int? bookingId,
    int? tripId,
    required String reportType,
    required String reason,
    String? description,
  }) async {
    final data = {
      'reportedUserId': reportedUserId,
      'bookingId': bookingId,
      'tripId': tripId,
      'reportType': reportType,
      'reason': reason,
      'description': description ?? '',
    };
    return await post('/reports', data);
  }

  // Check if user has already been reported for a booking
  Future<bool> hasReportedUser(int reportedUserId, {int? bookingId}) async {
    try {
      final endpoint = bookingId != null
          ? '/reports/has-reported?reportedUserId=$reportedUserId&bookingId=$bookingId'
          : '/reports/has-reported?reportedUserId=$reportedUserId';
      final response = await get(endpoint);
      return response['hasReported'] ?? false;
    } catch (e) {
      return false;
    }
  }
}

