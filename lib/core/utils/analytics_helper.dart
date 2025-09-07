import 'dart:io';
import 'package:flutter/foundation.dart';

class AnalyticsHelper {
  /// Track app installation (basic tracking without external packages)
  static Future<Map<String, dynamic>> trackAppInstall() async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      // This would be sent to your backend or analytics service
      final installData = {
        'event_type': 'app_install',
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
      };
      
      print('✅ App install tracked: $installData');
      return installData;
    } catch (e) {
      print('❌ Failed to track app install: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track user login
  static Future<Map<String, dynamic>> trackUserLogin({
    required String method,
    required String userRole,
    String? userId,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final loginData = {
        'event_type': 'user_login',
        'method': method,
        'user_role': userRole,
        'user_id': userId,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ User login tracked: $loginData');
      return loginData;
    } catch (e) {
      print('❌ Failed to track user login: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track user registration
  static Future<Map<String, dynamic>> trackUserRegistration({
    required String userType,
    required String method,
    String? userId,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final registrationData = {
        'event_type': 'user_registration',
        'user_type': userType,
        'method': method,
        'user_id': userId,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ User registration tracked: $registrationData');
      return registrationData;
    } catch (e) {
      print('❌ Failed to track user registration: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track screen views
  static Future<Map<String, dynamic>> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final screenData = {
        'event_type': 'screen_view',
        'screen_name': screenName,
        'screen_class': screenClass,
        'parameters': parameters,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ Screen view tracked: $screenName');
      return screenData;
    } catch (e) {
      print('❌ Failed to track screen view: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track feature usage
  static Future<Map<String, dynamic>> trackFeatureUsage({
    required String featureName,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final featureData = {
        'event_type': 'feature_usage',
        'feature_name': featureName,
        'action': action,
        'parameters': parameters,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ Feature usage tracked: $featureName');
      return featureData;
    } catch (e) {
      print('❌ Failed to track feature usage: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track app errors
  static Future<Map<String, dynamic>> trackError({
    required String errorType,
    required String errorMessage,
    String? screenName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final errorData = {
        'event_type': 'app_error',
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': screenName,
        'parameters': parameters,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ Error tracked: $errorType');
      return errorData;
    } catch (e) {
      print('❌ Failed to track error: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Track user engagement
  static Future<Map<String, dynamic>> trackUserEngagement({
    required String action,
    String? screenName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      final engagementData = {
        'event_type': 'user_engagement',
        'action': action,
        'screen_name': screenName,
        'parameters': parameters,
        'device_info': deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ User engagement tracked: $action');
      return engagementData;
    } catch (e) {
      print('❌ Failed to track user engagement: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Get basic device information (Play Store safe)
  static Future<Map<String, String>> _getBasicDeviceInfo() async {
    try {
      return {
        'device_type': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'is_emulator': kDebugMode.toString(),
        'app_version': '1.0.0', // This would come from package_info_plus
        'build_number': '1', // This would come from package_info_plus
      };
    } catch (e) {
      print('❌ Error getting basic device info: $e');
      return {
        'device_type': 'error',
        'platform': 'error',
        'platform_version': 'error',
        'is_emulator': 'error',
        'app_version': 'error',
        'build_number': 'error',
      };
    }
  }
  
  /// Get device statistics for monitoring
  static Future<Map<String, dynamic>> getDeviceStats() async {
    try {
      final deviceInfo = await _getBasicDeviceInfo();
      
      return {
        'device_type': deviceInfo['device_type'],
        'platform': deviceInfo['platform'],
        'platform_version': deviceInfo['platform_version'],
        'is_emulator': deviceInfo['is_emulator'],
        'app_version': deviceInfo['app_version'],
        'build_number': deviceInfo['build_number'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting device stats: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
