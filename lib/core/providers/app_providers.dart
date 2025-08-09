import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/security_service.dart';
import '../services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_providers.g.dart';

// Auth State Provider
@riverpod
class AuthState extends _$AuthState {
  @override
  AuthStateData build() {
    // Start with loading state and immediately check auth
    Future.microtask(() => checkAuthStatus());
    return const AuthStateData(
      isAuthenticated: false,
      isLoading: true, // Start with loading true
      user: null,
      error: null,
    );
  }

  Future<void> login(
    String token,
    String role, {
    Map<String, dynamic>? userData,
  }) async {
    print('🔐 Starting login process...');
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

      // Update state with authentication complete - DO NOT touch isLoading
      state = state.copyWith(
        isAuthenticated: true,
        user: UserData(email: email, name: name, role: role),
        error: null, // Clear any previous errors
      );

      print('✅ Login process completed successfully');
    } catch (e) {
      print('❌ Login process failed: $e');
      state = state.copyWith(isAuthenticated: false, error: e.toString());
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

  const AuthStateData({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.error,
  });

  AuthStateData copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserData? user,
    String? error,
  }) {
    return AuthStateData(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
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
