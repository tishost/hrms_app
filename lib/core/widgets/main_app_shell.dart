import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'owner_bottom_nav.dart';
import 'custom_will_pop_scope.dart';

class MainAppShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainAppShell({required this.child, super.key});

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate based on index
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/properties');
        break;
      case 2:
        context.go('/units');
        break;
      case 3:
        context.go('/tenants');
        break;
      case 4:
        context.go('/billing');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Update current index based on route
    if (currentRoute.contains('dashboard')) {
      _currentIndex = 0;
    } else if (currentRoute.contains('properties')) {
      _currentIndex = 1;
    } else if (currentRoute.contains('units')) {
      _currentIndex = 2;
    } else if (currentRoute.contains('tenants')) {
      _currentIndex = 3;
    } else if (currentRoute.contains('billing')) {
      _currentIndex = 4;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
