import 'package:flutter/foundation.dart';

class ColorService {
  // Common vehicle colors with their hex codes
  static const List<Map<String, dynamic>> vehicleColors = [
    {'name': 'White', 'hex': '#FFFFFF', 'category': 'Light'},
    {'name': 'Black', 'hex': '#000000', 'category': 'Dark'},
    {'name': 'Silver', 'hex': '#C0C0C0', 'category': 'Light'},
    {'name': 'Gray', 'hex': '#808080', 'category': 'Neutral'},
    {'name': 'Red', 'hex': '#FF0000', 'category': 'Bright'},
    {'name': 'Blue', 'hex': '#0000FF', 'category': 'Bright'},
    {'name': 'Green', 'hex': '#008000', 'category': 'Bright'},
    {'name': 'Yellow', 'hex': '#FFFF00', 'category': 'Bright'},
    {'name': 'Orange', 'hex': '#FFA500', 'category': 'Bright'},
    {'name': 'Brown', 'hex': '#A52A2A', 'category': 'Neutral'},
    {'name': 'Beige', 'hex': '#F5F5DC', 'category': 'Light'},
    {'name': 'Gold', 'hex': '#FFD700', 'category': 'Metallic'},
    {'name': 'Champagne', 'hex': '#F7E7CE', 'category': 'Metallic'},
    {'name': 'Pearl White', 'hex': '#F8F8FF', 'category': 'Light'},
    {'name': 'Metallic Black', 'hex': '#1C1C1C', 'category': 'Dark'},
    {'name': 'Dark Blue', 'hex': '#00008B', 'category': 'Dark'},
    {'name': 'Navy Blue', 'hex': '#000080', 'category': 'Dark'},
    {'name': 'Forest Green', 'hex': '#228B22', 'category': 'Dark'},
    {'name': 'Burgundy', 'hex': '#800020', 'category': 'Dark'},
    {'name': 'Purple', 'hex': '#800080', 'category': 'Bright'},
    {'name': 'Pink', 'hex': '#FFC0CB', 'category': 'Bright'},
    {'name': 'Turquoise', 'hex': '#40E0D0', 'category': 'Bright'},
    {'name': 'Lime Green', 'hex': '#32CD32', 'category': 'Bright'},
    {'name': 'Crimson', 'hex': '#DC143C', 'category': 'Bright'},
    {'name': 'Maroon', 'hex': '#800000', 'category': 'Dark'},
    {'name': 'Olive', 'hex': '#808000', 'category': 'Neutral'},
    {'name': 'Teal', 'hex': '#008080', 'category': 'Neutral'},
    {'name': 'Indigo', 'hex': '#4B0082', 'category': 'Dark'},
    {'name': 'Cyan', 'hex': '#00FFFF', 'category': 'Bright'},
    {'name': 'Magenta', 'hex': '#FF00FF', 'category': 'Bright'},
  ];

  // Get all colors
  static List<Map<String, dynamic>> getAllColors() {
    return List.from(vehicleColors);
  }

  // Search colors by query
  static List<Map<String, dynamic>> searchColors(String query) {
    if (query.isEmpty) {
      return vehicleColors;
    }
    
    final queryLower = query.toLowerCase();
    return vehicleColors.where((color) {
      final name = color['name'].toString().toLowerCase();
      final category = color['category'].toString().toLowerCase();
      return name.contains(queryLower) || category.contains(queryLower);
    }).toList();
  }

  // Get colors by category
  static List<Map<String, dynamic>> getColorsByCategory(String category) {
    return vehicleColors.where((color) => 
      color['category'].toString().toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Get all categories
  static List<String> getAllCategories() {
    return vehicleColors.map((color) => color['category'].toString()).toSet().toList();
  }

  // Get color by name
  static Map<String, dynamic>? getColorByName(String name) {
    try {
      return vehicleColors.firstWhere((color) => 
        color['name'].toString().toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
}
















