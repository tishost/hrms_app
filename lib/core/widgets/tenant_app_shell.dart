import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../features/tenant/presentation/widgets/tenant_bottom_nav.dart';
import 'package:hrms_app/core/utils/app_colors.dart';

class TenantAppShell extends StatefulWidget {
  final Widget child;

  const TenantAppShell({required this.child, super.key});

  @override
  State<TenantAppShell> createState() => _TenantAppShellState();
}

class _TenantAppShellState extends State<TenantAppShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMoreOpen = false;

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
    // If 'More' tapped, show in-body menu on dashboard and keep bottom nav visible
    if (index == 3) {
      setState(() {
        _currentIndex = 3;
      });
      final String loc = GoRouterState.of(context).matchedLocation;
      final bool onDashboard = loc.contains('dashboard');
      if (!onDashboard) {
        context.go('/tenant/dashboard');
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _isMoreOpen = true);
        });
      } else {
        setState(() => _isMoreOpen = true);
      }
      return;
    }

    // Close panel if open when switching to other tabs
    if (_isMoreOpen) {
      setState(() => _isMoreOpen = false);
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
    // Debounce: if already on the target route, just update index and return
    if (currentRoute == desiredRoute) {
      setState(() => _currentIndex = index);
      return;
    }

    setState(() => _currentIndex = index);
    context.go(desiredRoute);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Update current index based on route (but keep 'More' selected when open)
    if (_isMoreOpen) {
      _currentIndex = 3;
    } else {
      if (currentRoute.contains('dashboard')) {
        _currentIndex = 0;
      } else if (currentRoute.contains('billing')) {
        _currentIndex = 1;
      } else if (currentRoute.contains('profile')) {
        _currentIndex = 2;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Close in-body More panel first
        if (_isMoreOpen) {
          setState(() => _isMoreOpen = false);
          return;
        }

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
        key: _scaffoldKey,
        body: Stack(children: [widget.child, _buildInBodyMorePanel()]),
        bottomNavigationBar: TenantBottomNav(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildInBodyMorePanel() {
    final String loc = GoRouterState.of(context).matchedLocation;
    final bool onDashboard = loc.contains('dashboard');
    if (!onDashboard) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final double panelWidth = media.size.width * 0.85;
    final double clampedWidth = panelWidth.clamp(280.0, 360.0);
    final double topInset = media.padding.top;
    final double bottomInset =
        media.padding.bottom + 3; // reduce gap above bottom nav

    return IgnorePointer(
      ignoring: !_isMoreOpen,
      child: Stack(
        children: [
          // Backdrop (does NOT cover bottom nav area)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: AnimatedOpacity(
              opacity: _isMoreOpen ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () => setState(() => _isMoreOpen = false),
                child: Container(color: Colors.black),
              ),
            ),
          ),

          // Slide-in panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            top: topInset,
            right: _isMoreOpen ? 0 : -clampedWidth,
            bottom: bottomInset,
            width: clampedWidth,
            child: Material(
              elevation: 12,
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        children: const [
                          Icon(Icons.menu, size: 24, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Language pill (placeholder non-functional)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'English',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.home_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Dashboard',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        setState(() => _isMoreOpen = false);
                        context.go('/tenant/dashboard');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Billing',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        setState(() => _isMoreOpen = false);
                        context.go('/tenant/billing');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Profile',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        setState(() => _isMoreOpen = false);
                        context.go('/tenant/profile');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Rent Agreement',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        setState(() => _isMoreOpen = false);
                        context.go('/tenant/rent-agreement');
                      },
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          setState(() => _isMoreOpen = false);
                          await AuthService.logout();
                          if (!mounted) return;
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Out'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
