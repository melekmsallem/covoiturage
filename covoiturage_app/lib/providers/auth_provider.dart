import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isAuthenticated = _token != null;
    if (_isAuthenticated) {
      _user = {
        'id': prefs.getInt('user_id'),
        'username': prefs.getString('username'),
        'email': prefs.getString('email'),
        'firstName': prefs.getString('firstName'),
        'lastName': prefs.getString('lastName'),
        'role': prefs.getString('role'),
      };
    }
    notifyListeners();
  }

  Future<void> login(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', user['id']);
    await prefs.setString('username', user['username']);
    await prefs.setString('email', user['email']);
    await prefs.setString('firstName', user['firstName']);
    await prefs.setString('lastName', user['lastName']);
    await prefs.setString('role', user['role']);

    _token = token;
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _token = null;
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

