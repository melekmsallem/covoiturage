import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService.instance;

  // Get dashboard statistics
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _apiService.get('/dashboard/stats');
      return response;
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return null;
    }
  }

  // Get recent trips
  Future<List<dynamic>> getRecentTrips({int limit = 5}) async {
    try {
      final response = await _apiService.getDynamic('/dashboard/recent-trips?limit=$limit');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error getting recent trips: $e');
      return [];
    }
  }

  // Get upcoming trips
  Future<List<dynamic>> getUpcomingTrips() async {
    try {
      final response = await _apiService.getDynamic('/dashboard/upcoming-trips');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error getting upcoming trips: $e');
      return [];
    }
  }

  // Get earnings summary (for drivers)
  Future<Map<String, dynamic>?> getEarningsSummary() async {
    try {
      final response = await _apiService.get('/dashboard/earnings');
      return response;
    } catch (e) {
      print('Error getting earnings summary: $e');
      return null;
    }
  }

  // Get trip history
  Future<List<dynamic>> getTripHistory({int page = 0, int size = 10}) async {
    try {
      final response = await _apiService.getDynamic('/dashboard/trip-history?page=$page&size=$size');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error getting trip history: $e');
      return [];
    }
  }

  // Get favorite drivers (for passengers)
  Future<List<dynamic>> getFavoriteDrivers() async {
    try {
      final response = await _apiService.getDynamic('/dashboard/favorite-drivers');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error getting favorite drivers: $e');
      return [];
    }
  }

  // Get complete dashboard overview
  Future<Map<String, dynamic>?> getDashboardOverview() async {
    try {
      final response = await _apiService.get('/dashboard/overview');
      return response;
    } catch (e) {
      print('Error getting dashboard overview: $e');
      return null;
    }
  }
}
