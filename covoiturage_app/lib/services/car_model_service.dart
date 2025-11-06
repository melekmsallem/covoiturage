import 'package:flutter/foundation.dart';
import 'api_service.dart';

class CarModelService {
  static const String _baseUrl = '/car-models';

  // Get all car models
  static Future<List<Map<String, dynamic>>> getAllCarModels() async {
    try {
      // Public endpoint; avoid auth header issues on some devices
      final response = await ApiService.instance.getPublic(_baseUrl);
      debugPrint('Car models API response: $response');
      
      if (response is List) {
        final List<dynamic> list = response;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        debugPrint('Parsed ${result.length} car models');
        return result;
      } else if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> list = response['data'] as List;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        debugPrint('Parsed ${result.length} car models from data field');
        return result;
      } else {
        debugPrint('Unexpected response format: $response');
        return [];
      }
    } catch (e) {
      debugPrint('Failed to get car models: $e');
      throw Exception('Failed to get car models: $e');
    }
  }

  // Search car models by query
  static Future<List<Map<String, dynamic>>> searchCarModels(String query) async {
    try {
      final response = await ApiService.instance.getPublic('$_baseUrl/search?query=$query');
      if (response is List) {
        final List<dynamic> list = response;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        return result;
      } else if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> list = response['data'] as List;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Failed to search car models: $e');
      throw Exception('Failed to search car models: $e');
    }
  }

  // Get all brands
  static Future<List<String>> getAllBrands() async {
    try {
      final response = await ApiService.instance.getPublic('$_baseUrl/brands');
      if (response is List) {
        final List<dynamic> list = response;
        final List<String> result = [];
        for (var item in list) {
          result.add(item.toString());
        }
        return result;
      } else if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> list = response['data'] as List;
        final List<String> result = [];
        for (var item in list) {
          result.add(item.toString());
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Failed to get brands: $e');
      throw Exception('Failed to get brands: $e');
    }
  }

  // Get models by brand
  static Future<List<Map<String, dynamic>>> getModelsByBrand(String brand) async {
    try {
      final response = await ApiService.instance.getPublic('$_baseUrl/brand/$brand');
      if (response is List) {
        final List<dynamic> list = response;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        return result;
      } else if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> list = response['data'] as List;
        final List<Map<String, dynamic>> result = [];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          }
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Failed to get models by brand: $e');
      throw Exception('Failed to get models by brand: $e');
    }
  }

  // Initialize car models data
  static Future<void> initializeCarModels() async {
    try {
      await ApiService.instance.post('$_baseUrl/initialize', {});
    } catch (e) {
      debugPrint('Failed to initialize car models: $e');
      throw Exception('Failed to initialize car models: $e');
    }
  }
}