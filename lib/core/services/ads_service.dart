import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ad.dart';
import 'api_service.dart';

class AdsService {
  final ApiService _apiService;

  AdsService(this._apiService);

  /// Get ads for dashboard based on type (tenant/owner)
  Future<List<Ad>> getDashboardAds({required String type}) async {
    try {
      print('🔍 [AdsService] Fetching ads for type: $type');
      print('🔍 [AdsService] Using ApiService with protected endpoints');

      final response = await _apiService.get(
        '/ads/dashboard',
        queryParameters: {'type': type},
      );

      print('✅ [AdsService] Response received: ${response.statusCode}');
      print('✅ [AdsService] Response data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Check if ads system is disabled
        final adsEnabled = data['ads_enabled'] ?? true;
        if (adsEnabled == false) {
          print('🔍 [AdsService] Ads system is disabled, returning empty list');
          return [];
        }

        final List<dynamic> adsData = data['ads'];
        return adsData.map((adData) => Ad.fromJson(adData)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch ads');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching ads: $e');
    }
  }

  /// Record ad click for analytics
  Future<bool> recordAdClick(int adId) async {
    try {
      final response = await _apiService.post('/ads/$adId/click');

      if (response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to record click');
      }
    } on DioException catch (e) {
      // Don't throw error for click tracking - it's not critical
      print('Failed to record ad click: ${e.message}');
      return false;
    } catch (e) {
      print('Error recording ad click: $e');
      return false;
    }
  }

  /// Get ads by location with limit
  Future<List<Ad>> getAdsByLocation({
    required String location,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/ads/location',
        queryParameters: {'location': location, 'limit': limit},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Check if ads system is disabled
        final adsEnabled = data['ads_enabled'] ?? true;
        if (adsEnabled == false) {
          print('🔍 [AdsService] Ads system is disabled, returning empty list');
          return [];
        }

        final List<dynamic> adsData = data['ads'];
        return adsData.map((adData) => Ad.fromJson(adData)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch ads');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching ads: $e');
    }
  }

  /// Get ads statistics
  Future<Map<String, dynamic>> getAdsStats() async {
    try {
      final response = await _apiService.get('/ads/stats');

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch stats');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }
}
