import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is driver
  bool get isDriver => _user?['role'] == 'CONDUCTEUR';
  
  // Check if user is passenger
  bool get isPassenger => _user?['role'] == 'PASSAGER';
  
  // Get user full name
  String get userFullName {
    if (_user == null) return '';
    return '${_user!['firstName']} ${_user!['lastName']}';
  }

  // Get user email
  String get userEmail => _user?['email'] ?? '';

  // Get user phone
  String get userPhone => _user?['phoneNumber'] ?? '';

  AuthProvider() {
    _loadUserFromStorage();
  }

  // Load user from local storage
  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userData = prefs.getString('user_data');

      if (token != null && userData != null) {
        _token = token;
        _user = jsonDecode(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      await _clearUserData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save user data to local storage
  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('jwt_token', _token!);
    }
    if (_user != null) {
      await prefs.setString('user_data', jsonEncode(_user));
    }
  }

  // Clear user data from local storage
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  // Sign up
  Future<bool> signUp({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.signUp(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
        licenseNumber: licenseNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
      );

      if (response['token'] != null) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;
        await _saveUserToStorage();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign in
  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.signIn(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (response['token'] != null) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;
        await _saveUserToStorage();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.signOut();
    } catch (e) {
      print('Error during signout: $e');
    }

    _isAuthenticated = false;
    _token = null;
    _user = null;
    _error = null;
    await _clearUserData();

    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This would call an update profile API endpoint
      // For now, we'll just update the local data
      if (_user != null) {
        if (firstName != null) _user!['firstName'] = firstName;
        if (lastName != null) _user!['lastName'] = lastName;
        if (phoneNumber != null) _user!['phoneNumber'] = phoneNumber;
        if (vehicleModel != null) _user!['vehicleModel'] = vehicleModel;
        if (vehicleColor != null) _user!['vehicleColor'] = vehicleColor;
        if (vehiclePlate != null) _user!['vehiclePlate'] = vehiclePlate;

        await _saveUserToStorage();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await ApiService.testConnection();
      return response.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}


