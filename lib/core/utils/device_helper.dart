import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceHelper {
  /// Check if running on emulator
  static bool get isEmulator {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      // Check for emulator-specific properties
      try {
        final androidId = android_id ?? '';
        final buildFingerprint = build_fingerprint ?? '';
        final buildModel = build_model ?? '';

        return androidId.contains('generic') ||
            buildFingerprint.contains('generic') ||
            buildModel.contains('sdk') ||
            buildModel.contains('emulator') ||
            buildFingerprint.contains('sdk') ||
            buildFingerprint.contains('emulator');
      } catch (e) {
        print('Error checking emulator: $e');
        return false;
      }
    }

    return false;
  }

  /// Get Android ID (emulator specific)
  static String? get android_id {
    try {
      // This would need platform-specific implementation
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get build fingerprint
  static String? get build_fingerprint {
    try {
      // This would need platform-specific implementation
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get build model
  static String? get build_model {
    try {
      // This would need platform-specific implementation
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if we can proceed without permission (for emulator)
  static bool get canProceedWithoutPermission {
    return isEmulator;
  }
}
