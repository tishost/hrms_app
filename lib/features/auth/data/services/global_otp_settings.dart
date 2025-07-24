// import 'package:hrms_app/services/otp_settings_service.dart';
import 'dart:async';

class GlobalOtpSettings {
  static bool _isOtpEnabled = true;
  static bool _isOtpRequiredForRegistration = true;
  static bool _isOtpRequiredForLogin = false;
  static bool _isOtpRequiredForPasswordReset = true;
  static bool _isInitialized = false;
  static Timer? _refreshTimer;

  /// Initialize OTP settings on app startup
  static Future<void> initialize() async {
    try {
      print('Initializing OTP settings...');

      // Clear any existing cache
      // OtpSettingsService.clearCache();

      // Get latest settings from server
      // final settings = await OtpSettingsService.getOtpSettings();
      final settings = <String, dynamic>{};

      _isOtpEnabled = settings['is_enabled'] ?? true;
      _isOtpRequiredForRegistration =
          settings['require_otp_for_registration'] ?? true;
      _isOtpRequiredForLogin = settings['require_otp_for_login'] ?? false;
      _isOtpRequiredForPasswordReset =
          settings['require_otp_for_password_reset'] ?? true;
      _isInitialized = true;

      print('OTP Settings initialized:');
      print('- OTP System Enabled: $_isOtpEnabled');
      print('- OTP Required for Registration: $_isOtpRequiredForRegistration');
      print('- OTP Required for Login: $_isOtpRequiredForLogin');
      print(
        '- OTP Required for Password Reset: $_isOtpRequiredForPasswordReset',
      );

      // Start periodic refresh (every 2 minutes)
      _startPeriodicRefresh();
    } catch (e) {
      print('Error initializing OTP settings: $e');
      // Use default values if initialization fails
      _isOtpEnabled = true;
      _isOtpRequiredForRegistration = true;
      _isOtpRequiredForLogin = false;
      _isOtpRequiredForPasswordReset = true;
      _isInitialized = true;

      print('Using default OTP settings due to error');
    }
  }

  /// Start periodic refresh of OTP settings
  static void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      try {
        print('Refreshing OTP settings...');
        await refresh();
      } catch (e) {
        print('Error refreshing OTP settings: $e');
      }
    });
  }

  /// Stop periodic refresh
  static void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check if OTP system is enabled
  static bool isOtpEnabled() {
    return _isOtpEnabled;
  }

  /// Check if OTP is required for specific action
  static bool isOtpRequiredFor(String action) {
    // If OTP system is disabled, return false for all actions
    if (!_isOtpEnabled) {
      print('OTP system is disabled, returning false for action: $action');
      return false;
    }

    switch (action) {
      case 'registration':
        final required = _isOtpRequiredForRegistration;
        print(
          'OTP required for registration: $required (system enabled: $_isOtpEnabled)',
        );
        return required;
      case 'login':
        final required = _isOtpRequiredForLogin;
        print(
          'OTP required for login: $required (system enabled: $_isOtpEnabled)',
        );
        return required;
      case 'password_reset':
        final required = _isOtpRequiredForPasswordReset;
        print(
          'OTP required for password reset: $required (system enabled: $_isOtpEnabled)',
        );
        return required;
      default:
        print('Unknown OTP action: $action');
        return false;
    }
  }

  /// Refresh OTP settings (call this when admin changes settings)
  static Future<void> refresh() async {
    try {
      print('Refreshing OTP settings...');

      // Clear cache
      // OtpSettingsService.clearCache();

      // Get latest settings from server
      // final settings = await OtpSettingsService.getOtpSettings();
      final settings = <String, dynamic>{};

      bool oldOtpEnabled = _isOtpEnabled;
      bool oldRegistrationRequired = _isOtpRequiredForRegistration;

      _isOtpEnabled = settings['is_enabled'] ?? true;
      _isOtpRequiredForRegistration =
          settings['require_otp_for_registration'] ?? true;
      _isOtpRequiredForLogin = settings['require_otp_for_login'] ?? false;
      _isOtpRequiredForPasswordReset =
          settings['require_otp_for_password_reset'] ?? true;

      // Log changes
      if (oldOtpEnabled != _isOtpEnabled) {
        print(
          'OTP system enabled status changed: $oldOtpEnabled -> $_isOtpEnabled',
        );
      }
      if (oldRegistrationRequired != _isOtpRequiredForRegistration) {
        print(
          'OTP registration requirement changed: $oldRegistrationRequired -> $_isOtpRequiredForRegistration',
        );
      }

      print('OTP Settings refreshed successfully');
    } catch (e) {
      print('Error refreshing OTP settings: $e');
    }
  }

  /// Check if settings are initialized
  static bool isInitialized() {
    return _isInitialized;
  }

  /// Get all settings
  static Map<String, bool> getAllSettings() {
    return {
      'is_enabled': _isOtpEnabled,
      'require_otp_for_registration': _isOtpRequiredForRegistration,
      'require_otp_for_login': _isOtpRequiredForLogin,
      'require_otp_for_password_reset': _isOtpRequiredForPasswordReset,
    };
  }
}
