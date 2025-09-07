import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_helper.dart';
import 'api_service.dart';

class AnalyticsService {
  static const String _analyticsEndpoint = '/admin/analytics/receive-data';

  // Session management
  static String? _sessionId;
  static String? _userId;

  // API service reference
  static WidgetRef? _ref;

  /// Initialize analytics service with Riverpod ref
  static void initializeWithRef(WidgetRef ref) {
    print('🔍 [DEBUG] initializeWithRef() called');
    // Only initialize once
    if (_ref == null) {
      _ref = ref;
      print('✅ [DEBUG] Analytics Service initialized with Riverpod ref');
      print('✅ [DEBUG] _ref is now set: ${_ref != null}');
    } else {
      print('⚠️ [DEBUG] Analytics Service already initialized, skipping');
    }
  }

  /// Initialize analytics service
  static Future<void> initialize() async {
    // Generate unique session ID
    _sessionId = _generateSessionId();

    // Get stored user ID if available
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    print('🔍 Analytics Service initialized - Session: $_sessionId');
  }

  /// Set user ID for analytics tracking
  static Future<void> setUserId(String userId) async {
    _userId = userId;

    // Store in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    print('👤 Analytics User ID set: $userId');
  }

  /// Track app installation only once (first time)
  static Future<void> trackAppInstallOnce() async {
    print('🔍 [DEBUG] trackAppInstallOnce() called');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping app install tracking',
        );
        return;
      }

      // Check if app install was already tracked
      final prefs = await SharedPreferences.getInstance();
      final isFirstInstall = prefs.getBool('is_first_install') ?? true;

      if (!isFirstInstall) {
        print('✅ [DEBUG] App install already tracked, skipping');
        return;
      }

      print('✅ [DEBUG] First time install detected, proceeding with tracking');

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      final analyticsData = {
        'event_type': 'app_install',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'source': 'google_play',
          'install_method': 'fresh_install',
          'is_emulator': deviceInfo['is_emulator'] ?? false,
          'platform': Platform.operatingSystem,
        },
      };

      await _sendAnalyticsData(analyticsData);

      // Mark as installed so it won't track again
      await prefs.setBool('is_first_install', false);

      print('✅ App install tracked successfully (first time only)');
    } catch (e) {
      print('❌ Failed to track app install: $e');
    }
  }

  /// Track app installation
  static Future<void> trackAppInstall() async {
    print('🔍 [DEBUG] trackAppInstall() called');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping app install tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with app install tracking',
      );

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      final analyticsData = {
        'event_type': 'app_install',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'source': 'google_play',
          'install_method': 'fresh_install',
          'is_emulator': deviceInfo['is_emulator'] ?? false,
          'platform': Platform.operatingSystem,
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ App install tracked successfully');
    } catch (e) {
      print('❌ Failed to track app install: $e');
    }
  }

  /// Track app uninstall (when app is removed)
  static Future<void> trackAppUninstall() async {
    print('🔍 [DEBUG] trackAppUninstall() called');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping app uninstall tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with app uninstall tracking',
      );

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      final analyticsData = {
        'event_type': 'app_uninstall',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'uninstall_reason': 'user_removed',
          'last_session_duration': 'unknown',
          'platform': Platform.operatingSystem,
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ App uninstall tracked successfully');
    } catch (e) {
      print('❌ Failed to track app uninstall: $e');
    }
  }

  /// Track app session end (when app goes to background or is closed)
  static Future<void> trackAppSessionEnd() async {
    print('🔍 [DEBUG] trackAppSessionEnd() called');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping session end tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with session end tracking',
      );

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      final analyticsData = {
        'event_type': 'app_session_end',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'session_duration': 'unknown',
          'session_end_reason': 'background_or_closed',
          'platform': Platform.operatingSystem,
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ App session end tracked successfully');
    } catch (e) {
      print('❌ Failed to track app session end: $e');
    }
  }

  /// Track app session start (when app comes back to foreground)
  static Future<void> trackAppSessionStart() async {
    print('🔍 [DEBUG] trackAppSessionStart() called');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping session start tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with session start tracking',
      );

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      final analyticsData = {
        'event_type': 'app_session_start',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'session_start_reason': 'foreground',
          'platform': Platform.operatingSystem,
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ App session start tracked successfully');
    } catch (e) {
      print('❌ Failed to track app session start: $e');
    }
  }

  /// Track user login
  static Future<void> trackUserLogin({
    required String userId,
    String? email,
    String? loginMethod,
  }) async {
    print('🔍 [DEBUG] trackUserLogin() called for user: $userId');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping user login tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with user login tracking',
      );

      // Set user ID for this session
      await setUserId(userId);

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      // Convert user_id to integer if possible, otherwise use a fallback
      int? numericUserId;
      try {
        if (userId != 'unknown' &&
            !userId.startsWith('google_user_') &&
            !userId.startsWith('owner_') &&
            !userId.startsWith('tenant_') &&
            !userId.startsWith('new_user_') &&
            !userId.startsWith('existing_user_')) {
          numericUserId = int.parse(userId);
        }
      } catch (e) {
        print(
          '⚠️ [DEBUG] Could not parse userId as integer: $userId, using fallback',
        );
      }

      final analyticsData = {
        'event_type': 'user_login',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['os_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': numericUserId ?? 0, // Use integer user_id
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'login_method': loginMethod ?? 'email_password',
          'email': email,
          'platform': Platform.operatingSystem,
          'session_id': _sessionId,
          'original_user_id': userId, // Keep original for reference
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ User login tracked successfully for user: $userId');
    } catch (e) {
      print('❌ Failed to track user login: $e');
    }
  }

  /// Track user registration
  static Future<void> trackUserRegistration({
    required String userId,
    String? email,
    String? registrationMethod,
    Map<String, dynamic>? userProfile,
  }) async {
    print('🔍 [DEBUG] trackUserRegistration() called for user: $userId');
    try {
      // Check if analytics service is ready
      if (!isReady) {
        print(
          '⚠️ [DEBUG] Analytics service not ready, skipping user registration tracking',
        );
        return;
      }

      print(
        '✅ [DEBUG] Analytics service is ready, proceeding with user registration tracking',
      );

      // Set user ID for this session
      await setUserId(userId);

      final deviceInfo = await DeviceHelper.getDeviceInfo();
      final deviceId = await DeviceHelper.getDeviceId();

      // Convert user_id to integer if possible, otherwise use a fallback
      int? numericUserId;
      try {
        if (userId != 'unknown' &&
            !userId.startsWith('google_user_') &&
            !userId.startsWith('owner_') &&
            !userId.startsWith('tenant_') &&
            !userId.startsWith('new_user_') &&
            !userId.startsWith('existing_user_')) {
          numericUserId = int.parse(userId);
        }
      } catch (e) {
        print(
          '⚠️ [DEBUG] Could not parse userId as integer: $userId, using fallback',
        );
      }

      final analyticsData = {
        'event_type': 'user_registration',
        'device_type': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'web',
        'os_version': deviceInfo['app_version'] ?? 'unknown',
        'app_version': deviceInfo['app_version'] ?? '1.0.0',
        'device_model': deviceInfo['device_model'] ?? 'unknown',
        'manufacturer': deviceInfo['manufacturer'] ?? 'unknown',
        'screen_resolution': deviceInfo['screen_resolution'] ?? 'unknown',
        'device_id': deviceId,
        'user_id': numericUserId ?? 0, // Use integer user_id
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': {
          'registration_method': registrationMethod ?? 'email_signup',
          'email': email,
          'platform': Platform.operatingSystem,
          'session_id': _sessionId,
          'user_profile': userProfile,
          'original_user_id': userId, // Keep original for reference
        },
      };

      await _sendAnalyticsData(analyticsData);
      print('✅ User registration tracked successfully for user: $userId');
    } catch (e) {
      print('❌ Failed to track user registration: $e');
    }
  }

  /// Send analytics data to backend
  static Future<void> _sendAnalyticsData(Map<String, dynamic> data) async {
    try {
      print('🔍 [DEBUG] Starting to send analytics data...');

      // Check if analytics service is initialized
      if (_ref == null) {
        print(
          '⚠️ [DEBUG] Analytics service not initialized, skipping data send',
        );
        return;
      }

      print('✅ [DEBUG] Analytics service is initialized');

      // Get API service from provider
      final apiService = _ref!.read(apiServiceProvider);
      print('✅ [DEBUG] API service obtained from provider');

      // Add session ID to data payload
      final analyticsData = Map<String, dynamic>.from(data);
      analyticsData['session_id'] = _sessionId ?? 'unknown';

      print(
        '📤 [DEBUG] Sending analytics data to endpoint: $_analyticsEndpoint',
      );
      print('📤 [DEBUG] Data payload: ${jsonEncode(analyticsData)}');
      print('📤 [DEBUG] Session ID: ${analyticsData['session_id']}');
      print('📤 [DEBUG] Event type: ${analyticsData['event_type']}');

      final response = await apiService.post(
        _analyticsEndpoint,
        data: analyticsData,
      );

      print('📥 [DEBUG] Response received from API');
      print('📥 [DEBUG] Response status: ${response.statusCode}');
      print('📥 [DEBUG] Response data: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        print(
          '📊 [DEBUG] Analytics data sent successfully - ID: ${responseData['analytics_id']}',
        );
        print('✅ [DEBUG] Data should now be in database table');
      } else {
        print(
          '⚠️ [DEBUG] Analytics API returned error: ${responseData['message']}',
        );
        print('⚠️ [DEBUG] Full error response: ${jsonEncode(responseData)}');
      }
    } catch (e) {
      print('❌ [DEBUG] Failed to send analytics data: $e');
      print('❌ [DEBUG] Error type: ${e.runtimeType}');
      print('❌ [DEBUG] Stack trace: ${StackTrace.current}');
    }
  }

  /// Generate unique session ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'session_${timestamp}_$random';
  }

  /// Get current session ID
  static String? get sessionId => _sessionId;

  /// Get current user ID
  static String? get userId => _userId;

  /// Check if analytics service is ready
  static bool get isReady {
    final ready = _ref != null;
    print('🔍 [DEBUG] isReady check: $ready (_ref: ${_ref != null})');
    return ready;
  }

  /// Test method to manually trigger analytics
  static Future<void> testAnalytics() async {
    print('🧪 [DEBUG] testAnalytics() called');
    print('🧪 [DEBUG] Current state:');
    print('  - _ref: ${_ref != null}');
    print('  - _sessionId: $_sessionId');
    print('  - _userId: $_userId');
    print('  - isReady: $isReady');

    if (isReady) {
      print('🧪 [DEBUG] Testing analytics by sending test data...');
      await trackAppInstall();
    } else {
      print('🧪 [DEBUG] Analytics service not ready, cannot test');
    }
  }
}
