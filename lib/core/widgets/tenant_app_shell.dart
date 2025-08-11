import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/tenant/presentation/widgets/tenant_bottom_nav.dart';

class TenantAppShell extends StatefulWidget {
  final Widget child;

  const TenantAppShell({required this.child, super.key});

  @override
  State<TenantAppShell> createState() => _TenantAppShellState();
}

class _TenantAppShellState extends State<TenantAppShell> {
  int _currentIndex = 0;

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
    setState(() {
      _currentIndex = index;
    });

    // Navigate based on index
    switch (index) {
      case 0:
        context.go('/tenant/dashboard');
        break;
      case 1:
        context.go('/tenant/billing');
        break;
      case 2:
        context.go('/tenant/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Update current index based on route
    if (currentRoute.contains('dashboard')) {
      _currentIndex = 0;
    } else if (currentRoute.contains('billing')) {
      _currentIndex = 1;
    } else if (currentRoute.contains('profile')) {
      _currentIndex = 2;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check current route - if we're at tenant dashboard, show exit dialog
        final currentLocation = GoRouterState.of(context).matchedLocation;

        if (currentLocation == '/tenant/dashboard') {
          // We're at the tenant dashboard route, show exit dialog
          final shouldExit = await _showExitDialog(context);
          if (shouldExit && context.mounted) {
            SystemNavigator.pop();
          }
        } else if (context.canPop()) {
          // For other routes, navigate back
          context.pop();
        } else {
          // If can't pop, go to tenant dashboard
          context.go('/tenant/dashboard');
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: TenantBottomNav(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
