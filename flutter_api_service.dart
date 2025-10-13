import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081/api';
  static const String wsUrl = 'ws://localhost:8081/ws';
  
  // Get JWT token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  
  // Save JWT token to storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }
  
  // Remove JWT token from storage
  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
  
  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    String? licenseNumber,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
        if (role == 'CONDUCTEUR') ...{
          'licenseNumber': licenseNumber,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'vehiclePlate': vehiclePlate,
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } else {
      throw Exception('Signin failed: ${response.body}');
    }
  }

  static Future<void> signOut() async {
    await _removeToken();
  }

  // Trip endpoints
  static Future<List<dynamic>> getAvailableTrips() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/available'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trips: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> createTrip({
    required DateTime departureTime,
    required DateTime arrivalTime,
    required double pricePerSeat,
    required int maxSeats,
    required String description,
    required Map<String, dynamic> startPoint,
    required Map<String, dynamic> endPoint,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'departureTime': departureTime.toIso8601String(),
        'arrivalTime': arrivalTime.toIso8601String(),
        'pricePerSeat': pricePerSeat,
        'maxSeats': maxSeats,
        'description': description,
        'startPoint': startPoint,
        'endPoint': endPoint,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create trip: ${response.body}');
    }
  }

  static Future<List<dynamic>> searchTrips({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    DateTime? departureDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/search'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        if (departureDate != null) 'departureDate': departureDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search trips: ${response.body}');
    }
  }

  // Booking endpoints
  static Future<Map<String, dynamic>> createBooking({
    required int tripId,
    required int numberOfSeats,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'tripId': tripId,
        'numberOfSeats': numberOfSeats,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create booking: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> confirmBooking(int bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/confirm'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to confirm booking: ${response.body}');
    }
  }

  // Payment endpoints
  static Future<Map<String, dynamic>> createPayment({
    required int reservationId,
    required String paymentMethod,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'reservationId': reservationId,
        'paymentMethod': paymentMethod,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> processPayment({
    required int paymentId,
    required String transactionId,
    String? paymentDetails,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/process'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'transactionId': transactionId,
        'paymentDetails': paymentDetails,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process payment: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getPaymentByReservation({
    required int reservationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/reservation/$reservationId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {}; // No payment found
    } else {
      throw Exception('Failed to get payment: ${response.body}');
    }
  }

  static Future<List<dynamic>> getMyPayments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/my-payments'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get payments: ${response.body}');
    }
  }

  // Rating endpoints
  static Future<Map<String, dynamic>> createRating({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'tripId': tripId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create rating: ${response.body}');
    }
  }

  // Notification endpoints
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }

  static Future<int> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/count'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notification count: ${response.body}');
    }
  }

  // Test endpoint
  static Future<String> testConnection() async {
    final response = await http.get(
      Uri.parse('$baseUrl/test/health'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Connection test failed: ${response.body}');
    }
  }
}


