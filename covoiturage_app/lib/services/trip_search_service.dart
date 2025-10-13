import 'api_service.dart';

class TripSearchService {
  static final TripSearchService _instance = TripSearchService._internal();
  factory TripSearchService() => _instance;
  TripSearchService._internal();

  final ApiService _apiService = ApiService.instance;

  /// Search for trips with advanced filters
  Future<List<dynamic>> searchTrips(Map<String, dynamic> searchParams) async {
    try {
      final response = await _apiService.post('/trips/search', searchParams);
      return response['data'] ?? [];
    } catch (e) {
      throw Exception('Failed to search trips: $e');
    }
  }

  /// Get available trips (simple search)
  Future<List<dynamic>> getAvailableTrips() async {
    try {
      final response = await _apiService.getDynamic('/trips/available');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get available trips: $e');
    }
  }
}







