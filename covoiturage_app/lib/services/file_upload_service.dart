import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

class FileUploadService {
  static Future<String> _hostBase() async {
    if (kIsWeb) return 'http://localhost:8081';
    final apiBase = await ApiService.getResolvedBaseUrl(); // e.g., http://10.0.2.2:8081/api
    return apiBase.replaceFirst('/api', '');               // -> http://10.0.2.2:8081
  }

  /// Upload driver's license image
  static Future<Map<String, dynamic>> uploadLicenseImage({
    required File imageFile,
    required int userId,
  }) async {
    try {
      final baseUrl = await _hostBase();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/files/upload-license'),
      );

      // Add file with proper content type
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'webp') {
        contentType = 'image/webp';
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'license_$userId.${fileExtension}',
          contentType: MediaType.parse(contentType),
        ),
      );

      // Add user ID
      request.fields['userId'] = userId.toString();

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Upload failed: $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get license image URL
  static String getLicenseImageUrl(String filename) {
    // This method is sync; use web default for now. For mobile, URLs returned from upload response should be preferred.
    final base = kIsWeb ? 'http://localhost:8081' : '';
    return base.isEmpty ? '/api/files/license/$filename' : '$base/api/files/license/$filename';
  }

  /// Delete license image
  static Future<bool> deleteLicenseImage(String filename) async {
    try {
      final baseUrl = await _hostBase();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/files/license/$filename'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}



