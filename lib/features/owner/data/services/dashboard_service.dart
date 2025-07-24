import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('DEBUG: Calling dashboard stats API...');
      print('DEBUG: API URL: ${ApiConfig.getApiUrl("/dashboard/stats")}');

      final response = await _apiService.get('/dashboard/stats');

      print(
        'Dashboard Stats Response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Dashboard Stats Error: $e');
      // Return dummy data for testing
      return {
        'stats': {
          'total_tenants': 5,
          'total_units': 12,
          'total_properties': 3,
          'rent_collected': 50000,
          'total_dues': 15000,
          'vacant_units': 2,
          'rented_units': 10,
        },
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    try {
      print('DEBUG: Calling recent transactions API...');
      final response = await _apiService.get('/dashboard/recent-transactions');

      print(
        'Recent Transactions Response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      } else {
        throw Exception(
          'Failed to load recent transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Recent Transactions Error: $e');
      // Return dummy data for testing
      return [
        {
          'id': 1,
          'tenant_name': 'John Doe',
          'unit_name': 'Unit A-101',
          'type': 'rent_payment',
          'amount': 5000,
          'status': 'completed',
          'description': 'Monthly rent payment',
          'date': '2024-01-15',
          'is_credit': true,
        },
        {
          'id': 2,
          'tenant_name': 'Jane Smith',
          'unit_name': 'Unit B-202',
          'type': 'rent_payment',
          'amount': 4500,
          'status': 'completed',
          'description': 'Monthly rent payment',
          'date': '2024-01-14',
          'is_credit': true,
        },
      ];
    }
  }

  // Get tenant dashboard data
  Future<Map<String, dynamic>> getTenantDashboard() async {
    try {
      final response = await _apiService.get('/tenants/dashboard');

      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to load tenant dashboard');
      }
    } catch (e) {
      print('Error getting tenant dashboard: $e');
      rethrow;
    }
  }
}

// Dashboard Service Provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardService(apiService);
});
