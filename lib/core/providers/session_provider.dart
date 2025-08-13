import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

// Session state provider
final sessionStateProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      return SessionNotifier();
    });

// Session state
class SessionState {
  final bool isAuthenticated;
  final bool isSessionKilled;
  final String? errorMessage;

  SessionState({
    this.isAuthenticated = false,
    this.isSessionKilled = false,
    this.errorMessage,
  });

  SessionState copyWith({
    bool? isAuthenticated,
    bool? isSessionKilled,
    String? errorMessage,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSessionKilled: isSessionKilled ?? this.isSessionKilled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Session notifier
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState()) {
    _checkAuthStatus();
  }

  // Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    state = state.copyWith(isAuthenticated: isLoggedIn);
  }

  // Handle session kill
  Future<void> handleSessionKill() async {
    print('🚫 Session kill detected, clearing all data');

    // Clear all data
    await AuthService.handleSessionKill();

    // Update state
    state = state.copyWith(
      isAuthenticated: false,
      isSessionKilled: true,
      errorMessage:
          'Your session has been terminated by admin. Please login again.',
    );
  }

  // Handle regular logout
  Future<void> logout() async {
    print('🔐 Regular logout initiated');

    await AuthService.logout();

    state = state.copyWith(
      isAuthenticated: false,
      isSessionKilled: false,
      errorMessage: null,
    );
  }

  // Handle successful login
  Future<void> login() async {
    print('✅ Login successful, updating session state');

    state = state.copyWith(
      isAuthenticated: true,
      isSessionKilled: false,
      errorMessage: null,
    );
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Reset session kill state
  void resetSessionKill() {
    state = state.copyWith(isSessionKilled: false);
  }
}

// Global session kill handler
class SessionKillHandler {
  static void handleSessionKill(WidgetRef ref, GoRouter router) {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);

    // Handle session kill
    sessionNotifier.handleSessionKill();

    // Navigate to login screen
    try {
      router.go('/login');
    } catch (e) {
      // Fallback navigation
      router.go('/');
    }
  }
}
