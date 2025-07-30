import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/providers/app_providers.dart';

class CustomDrawer extends ConsumerWidget {
  final Function()? onLogout;

  const CustomDrawer({super.key, this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer title (left aligned)
            Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                bottom: 8.0,
                left: 20.0,
                right: 20.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Divider(),
            // Profile menu item

            // Menu items
            Expanded(
              child: ListView(
                children: [
                  _drawerItem(
                    Icons.home,
                    'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/dashboard');
                    },
                  ),
                  _drawerItem(
                    Icons.business,
                    'Properties',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/properties');
                    },
                  ),
                  _drawerItem(
                    Icons.home_work,
                    'Units',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/units');
                    },
                  ),
                  _drawerItem(
                    Icons.people,
                    'Tenants',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/tenants');
                    },
                  ),
                  _drawerItem(
                    Icons.receipt_long,
                    'Checkout Records',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/checkouts');
                    },
                  ),
                  _drawerItem(
                    Icons.attach_money,
                    'Billing',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/billing');
                    },
                  ),
                  _drawerItem(
                    Icons.assessment,
                    'Reports',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/reports');
                    },
                  ),
                ],
              ),
            ),
            Divider(),
            // Log Out button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.logout),
                label: Text(
                  'Log Out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed:
                    onLogout ??
                    () async {
                      await ref.read(authStateProvider.notifier).logout();
                      context.go('/login');
                    },
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      trailing: null,
    );
  }
}
