import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/back_button_provider.dart';

import '../../features/tenant/presentation/widgets/tenant_bottom_nav.dart';

/// CRITICAL: This shell manages tenant navigation using GoRouter ONLY
/// NEVER use Navigator.push() for page navigation in tenant pages
/// Always use context.go() to maintain shell navigation consistency
/// See: NAVIGATION_GUIDELINES.md for complete rules
class TenantAppShell extends ConsumerStatefulWidget {
  final Widget child;

  const TenantAppShell({required this.child, super.key});

  @override
  ConsumerState<TenantAppShell> createState() => _TenantAppShellState();
}

class _TenantAppShellState extends ConsumerState<TenantAppShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
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
        ) ??
        false;
  }

  void _onItemTapped(int index) {
    print('🔵 Navigation: Tab $index tapped, current: $_currentIndex');

    // Reset invoice viewing state when navigating away from invoice
    final backButtonState = ref.read(backButtonProvider);
    if (backButtonState.isViewingInvoice) {
      ref.read(backButtonProvider.notifier).setViewingInvoice(false);
      print('🔵 Navigation: Reset invoice viewing state');
    }

    // If 'More' tapped, navigate to more page
    if (index == 3) {
      _updateNavigationState(3, '/tenant/more');
      return;
    }

    String desiredRoute;
    switch (index) {
      case 0:
        desiredRoute = '/tenant/dashboard';
        break;
      case 1:
        desiredRoute = '/tenant/billing';
        break;
      case 2:
        desiredRoute = '/tenant/profile';
        break;
      default:
        desiredRoute = '/tenant/dashboard';
    }

    final currentRoute = GoRouterState.of(context).matchedLocation;
    print(
      '🔵 Navigation: Current route: $currentRoute, Desired: $desiredRoute',
    );

    // Update navigation state and navigate
    _updateNavigationState(index, desiredRoute);
  }

  void _updateNavigationState(int index, String route) {
    print('🔵 Navigation: Updating state to index=$index, route=$route');

    // Update local state
    setState(() {
      _currentIndex = index;
    });

    // Update local state only

    // Navigate to route
    context.go(route);

    print(
      '🔵 Navigation: State updated and navigated to $route (index: $index)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final backButtonState = ref.watch(backButtonProvider);

    // Update current index based on route and invoice viewing state
    if (currentRoute.contains('invoice') && backButtonState.isViewingInvoice) {
      // When on invoice page, keep billing tab selected
      _currentIndex = 1;
    } else if (currentRoute.contains('dashboard')) {
      _currentIndex = 0;
    } else if (currentRoute.contains('billing')) {
      _currentIndex = 1;
    } else if (currentRoute.contains('profile')) {
      _currentIndex = 2;
    } else if (currentRoute.contains('more')) {
      _currentIndex = 3;
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check if viewing invoice - handle through back button provider
        if (backButtonState.isViewingInvoice) {
          final handled = await ref
              .read(backButtonProvider.notifier)
              .handleBackPress(context, currentRoute);
          if (!handled) return;
        }

        // Check current route - if we're at tenant dashboard, show exit dialog
        final currentLocation = GoRouterState.of(context).matchedLocation;

        if (currentLocation == '/tenant/dashboard') {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit && context.mounted) {
            SystemNavigator.pop();
          }
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/tenant/dashboard');
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        bottomNavigationBar: TenantBottomNav(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
