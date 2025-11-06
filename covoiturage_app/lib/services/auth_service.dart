import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

class AuthService {
  static Future<String> _authBase() async {
    final base = kIsWeb ? 'http://localhost:8081/api' : await ApiService.getResolvedBaseUrl();
    return '$base/auth';
  }

  // Sign In
  Future<Map<String, dynamic>> signIn(String usernameOrEmail, String password) async {
    try {
      final baseUrl = await _authBase();
      final response = await http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to sign in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      // Use the correct endpoint: /api/users/check-username/{username}
      final base = kIsWeb ? 'http://localhost:8081/api' : await ApiService.getResolvedBaseUrl();
      final url = '$base/users/check-username/$username';
      
      print('🔍 Checking username availability: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Backend returns boolean directly, not wrapped in object
        final exists = jsonDecode(response.body);
        final isAvailable = !exists;
        print('✅ Username available: $isAvailable (exists: $exists)');
        return isAvailable; // Return true if username is available (not exists)
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false; // Assume not available if error
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return false; // Assume not available if error
    }
  }

  // Sign Up
  Future<Map<String, dynamic>> signUp({
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
    int? maxPassengers,
    String? preferredPaymentMethod,
  }) async {
    try {
      final baseUrl = await _authBase();
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'role': role == 'PASSAGER' ? 'Passager' : role == 'CONDUCTEUR' ? 'Conducteur' : role,
          if (licenseNumber != null) 'licenseNumber': licenseNumber,
          if (vehicleModel != null) 'vehicleModel': vehicleModel,
          if (vehicleColor != null) 'vehicleColor': vehicleColor,
          if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
          if (maxPassengers != null) 'maxPassengers': maxPassengers,
          if (preferredPaymentMethod != null) 'preferredPaymentMethod': preferredPaymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final base = kIsWeb ? 'http://localhost:8081/api' : await ApiService.getResolvedBaseUrl();
      final usersBaseUrl = '$base/users';
      final response = await http.put(
        Uri.parse('$usersBaseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

