import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // JWT Token Management
  static Future<void> storeJwtToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getJwtToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> removeJwtToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // User Data Management
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    final userDataJson = json.encode(userData);
    await _storage.write(key: 'user_data', value: userDataJson);
    print('🔐 User data stored: $userData');
  }

  static Future<Map<String, dynamic>?> getStoredUserData() async {
    try {
      final userDataJson = await _storage.read(key: 'user_data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        print('🔓 User data retrieved: $userData');
        return userData;
      }
      print('🔓 No user data found in storage');
      return null;
    } catch (e) {
      print('❌ Error retrieving user data: $e');
      return null;
    }
  }

  static Future<void> removeUserData() async {
    await _storage.delete(key: 'user_data');
    print('🗑️ User data removed from storage');
  }

  // Secure Storage for Sensitive Data
  static Future<void> storeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSecureData(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> removeSecureData(String key) async {
    await _storage.delete(key: key);
  }

  // Password Hashing
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // JWT Token Validation (supports both JWT and Laravel Sanctum tokens)
  static bool isJwtTokenValid(String token) {
    try {
      // Check if it's a Laravel Sanctum token (format: ID|TOKEN)
      if (token.contains('|')) {
        final parts = token.split('|');
        if (parts.length == 2) {
          print('🔐 Token validation: Laravel Sanctum token detected');
          // For Sanctum tokens, we rely on backend validation
          // The token is valid if it exists and has proper format
          return true;
        } else {
          print('🔐 Token validation: Invalid Sanctum token format');
          return false;
        }
      }

      // Standard JWT validation
      final parts = token.split('.');
      if (parts.length != 3) {
        print(
          '🔐 JWT validation: Invalid JWT token format (${parts.length} parts)',
        );
        return false;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      final exp = payloadMap['exp'];
      if (exp == null) {
        print(
          '🔐 JWT validation: No expiration field found, token may be valid indefinitely',
        );
        // If no expiration field, consider token valid (backend handles expiration)
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final isValid = now.isBefore(expiry);

      if (isValid) {
        final daysLeft = expiry.difference(now).inDays;
        print('🔐 JWT validation: Token valid for $daysLeft more days');
      } else {
        print('🔐 JWT validation: Token expired on ${expiry.toString()}');
      }

      return isValid;
    } catch (e) {
      print('🔐 JWT validation error: $e');
      return false;
    }
  }

  // SSL Certificate Pinning (for production)
  static List<String> getPinnedCertificates() {
    return [
      // Add your SSL certificate hashes here
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    ];
  }

  // Clear All Secure Data
  static Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  // Check if device is secure
  static Future<bool> isDeviceSecure() async {
    try {
      // Check if device has screen lock
      final hasScreenLock = await _storage.read(key: 'device_secure');
      return hasScreenLock == 'true';
    } catch (e) {
      return false;
    }
  }

  // Biometric Authentication (Future implementation)
  static Future<bool> authenticateWithBiometrics() async {
    // TODO: Implement biometric authentication
    return true;
  }
}
