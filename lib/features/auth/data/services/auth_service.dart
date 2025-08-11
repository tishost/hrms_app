import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Store token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userInfoKey);
    await prefs.remove('user_data'); // Clear dashboard user data
    await prefs.remove('dashboard_stats'); // Clear dashboard stats
    await prefs.remove('subscription_data'); // Clear subscription data
    print('DEBUG: All cached data cleared on logout');
  }

  // Get user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(_userInfoKey);
    if (userInfoString != null) {
      return json.decode(userInfoString);
    }
    return null;
  }

  // Store token (alias for storeToken)
  static Future<void> saveToken(String token) async {
    await storeToken(token);
  }

  // Remove token (alias for clearToken)
  static Future<void> removeToken() async {
    await clearToken();
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }

  // Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get stored credentials
  static Future<Map<String, String>?> getStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('stored_email');
    final password = prefs.getString('stored_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // Store credentials for auto-login
  static Future<void> storeCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_email', email);
    await prefs.setString('stored_password', password);
  }

  // Clear stored credentials
  static Future<void> clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stored_email');
    await prefs.remove('stored_password');
  }
}

// Auth Repository using Dio
class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  // Login with email/mobile and password
  Future<Map<String, dynamic>> login(
    String emailOrMobile,
    String password,
  ) async {
    try {
      // Determine if input is email or mobile
      bool isEmail = emailOrMobile.contains('@');
      String fieldName = isEmail ? 'email' : 'mobile';

      final response = await _apiService.post(
        '/login',
        data: {fieldName: emailOrMobile, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save token
        await AuthService.saveToken(data['token']);

        return data;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Auto-login with stored credentials
  Future<Map<String, dynamic>> autoLogin() async {
    try {
      final credentials = await AuthService.getStoredCredentials();
      if (credentials == null) {
        throw Exception('No stored credentials found');
      }

      return await login(credentials['email']!, credentials['password']!);
    } catch (e) {
      throw Exception('Auto-login failed: $e');
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post('/register', data: userData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        // Save token if provided
        if (data['token'] != null) {
          await AuthService.saveToken(data['token']);
        }

        return data;
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Register Owner (specific endpoint)
  Future<Map<String, dynamic>> registerOwner(
    Map<String, dynamic> ownerData,
  ) async {
    try {
      print('🔥 API Call: POST /register-owner');
      print('🔥 Data: $ownerData');

      final response = await _apiService.post(
        '/register-owner',
        data: ownerData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        print('✅ Owner Registration Success: $data');

        // Save token if provided
        if (data['token'] != null) {
          await AuthService.saveToken(data['token']);
          print('🔑 Token saved: ${data['token']}');
        }

        return data;
      } else {
        throw Exception('Owner registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Owner Registration Error: $e');
      throw Exception('Owner registration error: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get('/user/profile');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get profile: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Profile error: $e');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _apiService.put(
        '/user/profile',
        data: profileData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Profile update failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Profile update error: $e');
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.post(
        '/user/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Password change failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Password change error: $e');
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        '/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Forgot password failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Forgot password error: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiService.post(
        '/reset-password',
        data: {'token': token, 'password': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Password reset failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Password reset error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post('/logout');
    } catch (e) {
      // Even if logout API fails, clear local token
      print('Logout API error: $e');
    } finally {
      await AuthService.logout();
    }
  }
}

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});
