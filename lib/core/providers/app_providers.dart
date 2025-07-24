import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/security_service.dart';
import '../constants/app_constants.dart';

part 'app_providers.g.dart';

// Auth State Provider
@riverpod
class AuthState extends _$AuthState {
  @override
  AuthStateData build() {
    return const AuthStateData(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
    );
  }

  Future<void> login(String token, String role) async {
    print('DEBUG: AuthState.login called with token: $token, role: $role');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecurityService.storeJwtToken(token);
      print('DEBUG: Token stored successfully');

      final newState = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: UserData(email: '', name: 'User', role: role),
      );

      state = newState;
      print(
        'DEBUG: Auth state updated - isAuthenticated: ${state.isAuthenticated}, role: ${state.user?.role}',
      );
    } catch (e) {
      print('DEBUG: Error in login: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await SecurityService.removeJwtToken();
    state = const AuthStateData(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
    );
  }

  Future<void> checkAuthStatus() async {
    final token = await SecurityService.getJwtToken();
    if (token != null && SecurityService.isJwtTokenValid(token)) {
      // For now, assume owner role if token exists
      // In a real app, you might want to decode the JWT to get role
      state = state.copyWith(
        isAuthenticated: true,
        user: UserData(email: '', name: 'User', role: 'owner'),
      );
    } else {
      state = state.copyWith(isAuthenticated: false);
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
