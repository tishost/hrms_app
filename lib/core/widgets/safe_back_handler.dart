import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/providers/navigation_provider.dart';

class SafeBackHandler extends ConsumerWidget {
  final Widget child;
  final String? fallbackRoute;
  final VoidCallback? onBackPressed;
  final bool enableDoubleBackToExit;

  const SafeBackHandler({
    super.key,
    required this.child,
    this.fallbackRoute,
    this.onBackPressed,
    this.enableDoubleBackToExit = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        // If custom back handler is provided, use it
        if (onBackPressed != null) {
          onBackPressed!();
          return false;
        }

        // Check if we can pop to previous route
        if (context.canPop()) {
          // Update navigation state before popping
          ref.read(navigationServiceProvider).popRoute();
          return true;
        }

        // If no previous route, navigate to fallback or dashboard
        final targetRoute = fallbackRoute ?? '/dashboard';

        // Use microtask to avoid build conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(targetRoute);
        });

        return false;
      },
      child: child,
    );
  }
}

// Specialized back handler for dashboard with double-back-to-exit
class DashboardBackHandler extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardBackHandler({super.key, required this.child});

  @override
  ConsumerState<DashboardBackHandler> createState() =>
      _DashboardBackHandlerState();
}

class _DashboardBackHandlerState extends ConsumerState<DashboardBackHandler> {
  Future<bool> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('আপনি কি অ্যাপ থেকে বের হতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop(); // Close the app
    }

    // Prevent the route from popping automatically; we handle it above.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _confirmExit(context),
      child: widget.child,
    );
  }
}

// Subscription screen back handler
class SubscriptionBackHandler extends ConsumerWidget {
  final Widget child;

  const SubscriptionBackHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        // Check if we can pop to previous route
        if (context.canPop()) {
          ref.read(navigationServiceProvider).popRoute();
          return true;
        }

        // Navigate to dashboard if no previous route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/dashboard');
        });

        return false;
      },
      child: child,
    );
  }
}

// Payment webview back handler
class PaymentWebViewBackHandler extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onCancel;

  const PaymentWebViewBackHandler({
    super.key,
    required this.child,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog
        final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Payment'),
            content: const Text(
              'Are you sure you want to cancel this payment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldCancel == true) {
          if (onCancel != null) {
            onCancel!();
          } else {
            // Navigate back to subscription plans
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/subscription-plans');
            });
          }
        }

        return false;
      },
      child: child,
    );
  }
}
