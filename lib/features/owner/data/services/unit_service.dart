import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

class UnitService {
  static Future<List<Map<String, dynamic>>> getUnits({String? status}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final base = ApiConfig.getApiUrl('/units');
      final uri = Uri.parse(base).replace(
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
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
        return List<Map<String, dynamic>>.from(data['units'] ?? []);
      } else {
        throw Exception('Failed to load units');
      }
    } catch (e) {
      throw Exception('Error loading units: $e');
    }
  }

  static Future<Map<String, dynamic>> getUnitById(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/units/$id')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unit'] ?? {};
      } else {
        throw Exception('Failed to load unit');
      }
    } catch (e) {
      throw Exception('Error loading unit: $e');
    }
  }

  static Future<bool> addUnit(Map<String, dynamic> unitData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('/units')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(unitData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      if (response.statusCode == 403) {
        final data = json.decode(response.body);
        // Bubble up a descriptive error so UI can redirect
        throw Exception(data['error'] ?? 'Unit limit exceeded');
      }
      return false;
    } catch (e) {
      throw Exception('Error adding unit: $e');
    }
  }

  static Future<bool> updateUnit(int id, Map<String, dynamic> unitData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.put(
        Uri.parse(ApiConfig.getApiUrl('/units/$id')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(unitData),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating unit: $e');
    }
  }

  static Future<bool> deleteUnit(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.delete(
        Uri.parse(ApiConfig.getApiUrl('/units/$id')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      if (response.statusCode == 409) {
        final data = json.decode(response.body);
        if (data['requires_checkout'] == true) {
          throw Exception('REQUIRES_CHECKOUT');
        }
      }
      return false;
    } catch (e) {
      throw Exception('Error deleting unit: $e');
    }
  }

  // Get available charges
  static Future<List<Map<String, dynamic>>> getCharges() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/charges')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['charges'] ?? []);
      } else {
        throw Exception('Failed to load charges');
      }
    } catch (e) {
      throw Exception('Error loading charges: $e');
    }
  }
}
