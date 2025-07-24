import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/utils/api_config.dart';

class OtpSettingsService {
  static Map<String, dynamic>? _cachedSettings;
  static DateTime? _lastFetchTime;
  static const int _cacheDurationMinutes =
      1; // Reduce cache to 1 minute for faster updates

  /// Get OTP settings from server
  static Future<Map<String, dynamic>> getOtpSettings() async {
    // Check if we have cached settings and they're still valid
    if (_cachedSettings != null && _lastFetchTime != null) {
      final timeDifference = DateTime.now().difference(_lastFetchTime!);
      if (timeDifference.inMinutes < _cacheDurationMinutes) {
        return _cachedSettings!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${getApiUrl()}/otp-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _cachedSettings = data['data'];
          _lastFetchTime = DateTime.now();
          return _cachedSettings!;
        }
      }
    } catch (e) {
      print('Error fetching OTP settings: $e');
    }

    // Return default settings if fetch fails
    return _getDefaultSettings();
  }

  /// Check if OTP system is enabled
  static Future<bool> isOtpEnabled() async {
    final settings = await getOtpSettings();
    return settings['is_enabled'] ?? true;
  }

  /// Check if OTP is required for specific action
  static Future<bool> isOtpRequiredFor(String action) async {
    final settings = await getOtpSettings();

    // If OTP system is disabled, return false for all actions
    if (!(settings['is_enabled'] ?? true)) {
      print('OTP system is disabled');
      return false;
    }

    switch (action) {
      case 'registration':
        final required = settings['require_otp_for_registration'] ?? true;
        print('OTP required for registration: $required');
        return required;
      case 'login':
        final required = settings['require_otp_for_login'] ?? false;
        print('OTP required for login: $required');
        return required;
      case 'password_reset':
        final required = settings['require_otp_for_password_reset'] ?? true;
        print('OTP required for password reset: $required');
        return required;
      default:
        return false;
    }
  }

  /// Get OTP length from settings
  static Future<int> getOtpLength() async {
    final settings = await getOtpSettings();
    return settings['otp_length'] ?? 6;
  }

  /// Get OTP expiry minutes from settings
  static Future<int> getOtpExpiryMinutes() async {
    final settings = await getOtpSettings();
    return settings['otp_expiry_minutes'] ?? 10;
  }

  /// Get max attempts from settings
  static Future<int> getMaxAttempts() async {
    final settings = await getOtpSettings();
    return settings['max_attempts'] ?? 3;
  }

  /// Get resend cooldown seconds from settings
  static Future<int> getResendCooldownSeconds() async {
    final settings = await getOtpSettings();
    return settings['resend_cooldown_seconds'] ?? 60;
  }

  /// Clear cached settings (force refresh)
  static void clearCache() {
    _cachedSettings = null;
    _lastFetchTime = null;
    print('OTP settings cache cleared');
  }

  /// Get default settings
  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'is_enabled': true,
      'otp_length': 6,
      'otp_expiry_minutes': 10,
      'max_attempts': 3,
      'resend_cooldown_seconds': 60,
      'require_otp_for_registration': true,
      'require_otp_for_login': false,
      'require_otp_for_password_reset': true,
      'otp_message_template':
          'Your OTP is: {otp}. Valid for {minutes} minutes.',
    };
  }
}
