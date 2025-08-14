import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

class PropertyService {
  static Future<List<Map<String, dynamic>>> getProperties({
    String? status,
    bool includeArchived = false,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final baseUrl = ApiConfig.getApiUrl('/properties');
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'include_archived': includeArchived ? '1' : '0',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['properties'] ?? []);
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      throw Exception('Error loading properties: $e');
    }
  }

  static Future<Map<String, dynamic>> getPropertyById(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/properties/$id')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['property'] ?? {};
      } else {
        throw Exception('Failed to load property');
      }
    } catch (e) {
      throw Exception('Error loading property: $e');
    }
  }

  static Future<bool> deleteProperty(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.delete(
        Uri.parse(ApiConfig.getApiUrl('/properties/$id')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      // 409 means either archive or checkout required
      if (response.statusCode == 409) {
        final data = json.decode(response.body);
        if (data['requires_checkout'] == true) {
          throw Exception('REQUIRES_CHECKOUT');
        }
        if (data['can_archive'] == true) {
          throw Exception('ARCHIVE_REQUIRED');
        }
      }
      final msg = json.decode(response.body);
      throw Exception(msg['message'] ?? 'Failed to delete property');
    } catch (e) {
      throw Exception('Error deleting property: $e');
    }
  }

  static Future<bool> archiveProperty(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('/properties/$id/archive')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error archiving property: $e');
    }
  }
}
