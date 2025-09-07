import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Get device information for analytics (Play Store safe)
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        return {
          'device_type': 'android',
          'os_version': androidInfo.version.release,
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
          'device_model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'sdk_version': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await DeviceInfoPlugin().iosInfo;
        return {
          'device_type': 'ios',
          'os_version': iosInfo.systemVersion,
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'system_name': iosInfo.systemName,
        };
      } else {
        return {
          'device_type': 'unknown',
          'os_version': 'unknown',
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
        };
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
      return {
        'device_type': 'error',
        'os_version': 'error',
        'app_version': 'error',
        'build_number': 'error',
      };
    }
  }

  /// Generate a unique device identifier (Play Store safe)
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
        // Use a combination of device-specific info to create a unique ID
        final deviceId =
            '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.id}';
        return deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await DeviceInfoPlugin().iosInfo;
        // Use a combination of device-specific info to create a unique ID
        final deviceId =
            '${iosInfo.model}_${iosInfo.systemVersion}_${iosInfo.identifierForVendor}';
        return deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      } else {
        return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('❌ Error getting device ID: $e');
      return 'error_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get device statistics for monitoring
  static Future<Map<String, dynamic>> getDeviceStats() async {
    try {
      final deviceInfo = await getDeviceInfo();

      return {
        'device_type': deviceInfo['device_type'],
        'os_version': deviceInfo['os_version'],
        'app_version': deviceInfo['app_version'],
        'build_number': deviceInfo['build_number'],
        'is_emulator': isEmulator,
        'platform': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'unknown',
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
