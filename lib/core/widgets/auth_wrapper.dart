import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/security_service.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool requireAuth;

  const AuthWrapper({super.key, required this.child, this.requireAuth = true});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();
    // Don't check auth immediately - wait for auth state to stabilize
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    if (!widget.requireAuth) return;

    setState(() {
      _isCheckingAuth = true;
    });

    try {
      // Check auth state from provider instead of doing our own token validation
      final authState = ref.read(authStateProvider);

      // If auth state is loading, wait a bit more
      if (authState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        final updatedAuthState = ref.read(authStateProvider);
        if (updatedAuthState.isLoading) {
          // Still loading, wait more
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      final currentAuthState = ref.read(authStateProvider);

      if (!currentAuthState.isAuthenticated) {
        // Auth state shows not authenticated, redirect to login
        if (mounted) {
          _redirectToLogin();
        }
        return;
      }

      // Auth state shows authenticated, we're good
      print('DEBUG: AuthWrapper - User is authenticated, allowing access');
    } catch (e) {
      print('DEBUG: AuthWrapper - Error checking auth: $e');
      // Error occurred, redirect to login for safety
      if (mounted) {
        _redirectToLogin();
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  // Method to manually trigger session timeout for testing
  void _forceSessionTimeout() {
    _redirectToLogin();
  }

  void _redirectToLogin() {
    print('DEBUG: AuthWrapper - Redirecting to login');

    // Don't clear tokens here - let the auth state provider handle logout
    // This prevents conflicts during login process

    // Only logout if we're sure the user is not in the middle of logging in
    final authState = ref.read(authStateProvider);
    if (!authState.isLoading) {
      // Force logout in auth state
      ref.read(authStateProvider.notifier).logout();
    }

    // Navigate to login
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
