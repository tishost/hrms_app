import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/security_service.dart';
import '../services/api_service.dart';
import '../utils/analytics_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

part 'app_providers.g.dart';

// Auth State Provider
@riverpod
class AuthState extends _$AuthState {
  @override
  AuthStateData build() {
    // Don't immediately check auth status - let login process handle it
    // This prevents race conditions during login

    // Set up periodic token validation check (every 5 minutes) with initial delay
    Timer.periodic(const Duration(minutes: 5), (timer) {
      // Only validate if still authenticated and not disposed
      if (state.isAuthenticated && !state.isDisposed) {
        _validateTokenPeriodically();
      }
    });

    // Add initial delay before first token validation to avoid conflicts with login
    Timer(const Duration(minutes: 1), () {
      if (state.isAuthenticated && !state.isDisposed) {
        _validateTokenPeriodically();
      }
    });

    return const AuthStateData(
      isAuthenticated: false,
      isLoading:
          false, // Start with loading false since we're not checking auth immediately
      user: null,
      error: null,
      isDisposed: false,
    );
  }

  Future<void> login(
    String token,
    String role, {
    Map<String, dynamic>? userData,
  }) async {
    print('🔐 Starting login process...');

    // Set loading state to prevent auth conflicts
    state = state.copyWith(isLoading: true);

    try {
      // Store JWT token
      await SecurityService.storeJwtToken(token);

      // Extract user info from userData if available
      String email = userData?['email'] ?? '';
      String name = userData?['name'] ?? 'User';

      // Store user data for persistence
      final userDataToStore = {
        'email': email,
        'name': name,
        'role': role,
        'token': token,
        'loginTime': DateTime.now().toIso8601String(),
      };
      await SecurityService.storeUserData(userDataToStore);

      print('🔐 Auth State Updated - Role: $role, Name: $name, Email: $email');

      // Update state with authentication complete
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false, // Clear loading state
        user: UserData(email: email, name: name, role: role),
        error: null, // Clear any previous errors
      );

      print('✅ Login process completed successfully');
    } catch (e) {
      print('❌ Login process failed: $e');
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false, // Clear loading state on error
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await SecurityService.removeJwtToken();
    await SecurityService.removeUserData();
    state = const AuthStateData(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
      isDisposed: true,
    );
    print('🚪 User logged out successfully');
  }

  Future<void> checkAuthStatus() async {
    print('DEBUG: checkAuthStatus called');
    state = state.copyWith(isLoading: true);
    final token = await SecurityService.getJwtToken();
    await Future.delayed(const Duration(milliseconds: 500));

    if (token != null && SecurityService.isJwtTokenValid(token)) {
      // Try to get stored user data or default to owner
      final storedUserData = await SecurityService.getStoredUserData();
      String userRole = storedUserData?['role'] ?? 'owner';
      String userName = storedUserData?['name'] ?? 'User';
      String userEmail = storedUserData?['email'] ?? '';

      print('DEBUG: Token found, stored user data: $storedUserData');
      print(
        'DEBUG: Extracted - Role: $userRole, Name: $userName, Email: $userEmail',
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: UserData(email: userEmail, name: userName, role: userRole),
      );
      print(
        'DEBUG: Auth success, state: '
        'isAuthenticated: ${state.isAuthenticated}, '
        'isLoading: ${state.isLoading}, '
        'user: ${state.user?.name} (${state.user?.role})',
      );
    } else {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
      print(
        'DEBUG: Auth fail - No valid token found, '
        'isAuthenticated: ${state.isAuthenticated}, '
        'isLoading: ${state.isLoading}',
      );
    }
  }

  Future<void> _validateTokenPeriodically() async {
    try {
      final token = await SecurityService.getJwtToken();

      if (token == null) {
        print('🔄 No token found during validation, skipping');
        return;
      }

      if (!SecurityService.isJwtTokenValid(token)) {
        print('🔄 Token expired during validation, forcing logout');
        await logout();
      } else {
        print('✅ Token validation successful');
      }
    } catch (e) {
      print('❌ Error during periodic token validation: $e');
      // Don't immediately logout on validation errors, just log them
      // This prevents false positives from causing logout
    }
  }

  // Method to manually check auth status (called from app startup)
  Future<void> initializeAuthCheck() async {
    print('DEBUG: initializeAuthCheck called');
    await checkAuthStatus();
  }
}

// Theme Provider
@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

// Loading State Provider
@riverpod
class LoadingState extends _$LoadingState {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool loading) {
    state = loading;
  }
}

// Network State Provider
@riverpod
class NetworkState extends _$NetworkState {
  @override
  NetworkStateData build() {
    return const NetworkStateData(isConnected: true, connectionType: 'wifi');
  }

  void updateConnectionStatus(bool isConnected, String connectionType) {
    state = state.copyWith(
      isConnected: isConnected,
      connectionType: connectionType,
    );
  }
}

// Maintenance state
final maintenanceStateProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceData>((ref) {
      return MaintenanceNotifier(ref);
    });

class MaintenanceNotifier extends StateNotifier<MaintenanceData> {
  final Ref ref;
  MaintenanceNotifier(this.ref)
    : super(
        const MaintenanceData(
          isMaintenance: false,
          message: null,
          description: null,
          until: null,
        ),
      );

  Future<void> refresh() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getSystemStatus();
      final data = res.data as Map<String, dynamic>;
      final details = (data['details'] as Map<String, dynamic>?);
      state = MaintenanceData(
        isMaintenance: data['maintenance'] == true,
        message: details?['message'] as String?,
        description: details?['description'] as String?,
        until: details?['until'] as String?,
        companyName: details?['company_name'] as String?,
      );
    } catch (_) {
      // ignore
    }
  }
}

class MaintenanceData {
  final bool isMaintenance;
  final String? message;
  final String? description;
  final String? until;
  final String? companyName;

  const MaintenanceData({
    required this.isMaintenance,
    this.message,
    this.description,
    this.until,
    this.companyName,
  });
}

// Data Classes
class AuthStateData {
  final bool isAuthenticated;
  final bool isLoading;
  final UserData? user;
  final String? error;
  final bool isDisposed;

  const AuthStateData({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.error,
    this.isDisposed = false,
  });

  AuthStateData copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserData? user,
    String? error,
    bool? isDisposed,
  }) {
    return AuthStateData(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      isDisposed: isDisposed ?? this.isDisposed,
    );
  }
}

class UserData {
  final String email;
  final String name;
  final String? role;

  const UserData({required this.email, required this.name, this.role});
}

class NetworkStateData {
  final bool isConnected;
  final String connectionType;

  const NetworkStateData({
    required this.isConnected,
    required this.connectionType,
  });

  NetworkStateData copyWith({bool? isConnected, String? connectionType}) {
    return NetworkStateData(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

// Analytics Provider
class Analytics {
  /// Initialize analytics
  static Future<void> initialize() async {
    // Track app install
    await AnalyticsHelper.trackAppInstall();
  }
  
  /// Track user login
  static Future<void> trackLogin({
    required String method,
    required String userRole,
    String? userId,
  }) async {
    await AnalyticsHelper.trackUserLogin(
      method: method,
      userRole: userRole,
      userId: userId,
    );
  }
  
  /// Track user registration
  static Future<void> trackRegistration({
    required String userType,
    required String method,
    String? userId,
  }) async {
    await AnalyticsHelper.trackUserRegistration(
      userType: userType,
      method: method,
      userId: userId,
    );
  }
  
  /// Track screen view
  static Future<void> trackScreen({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    await AnalyticsHelper.trackScreenView(
      screenName: screenName,
      screenClass: screenClass,
      parameters: parameters,
    );
  }
  
  /// Track feature usage
  static Future<void> trackFeature({
    required String featureName,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    await AnalyticsHelper.trackFeatureUsage(
      featureName: featureName,
      action: action,
      parameters: parameters,
    );
  }
  
  /// Track errors
  static Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? screenName,
    Map<String, dynamic>? parameters,
  }) async {
    await AnalyticsHelper.trackError(
      errorType: errorType,
      errorMessage: errorMessage,
      screenName: screenName,
      parameters: parameters,
    );
  }
  
  /// Track user engagement
  static Future<void> trackEngagement({
    required String action,
    String? screenName,
    Map<String, dynamic>? parameters,
  }) async {
    await AnalyticsHelper.trackUserEngagement(
      action: action,
      screenName: screenName,
      parameters: parameters,
    );
  }
}
