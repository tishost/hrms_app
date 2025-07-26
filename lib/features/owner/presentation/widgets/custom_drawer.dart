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
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primary),
              title: Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/profile');
              },
            ),
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
                  Divider(),
                  _drawerItem(
                    Icons.stacked_bar_chart,
                    'Statements',
                    onTap: () {},
                  ),
                  _drawerItem(
                    Icons.warning_amber_rounded,
                    'Limits',
                    onTap: () {},
                  ),
                  _drawerItem(Icons.percent, 'Coupons', onTap: () {}),
                  _drawerItem(
                    Icons.info_outline,
                    'Information Update',
                    onTap: () {},
                  ),
                  _drawerItem(
                    Icons.person_add_alt,
                    'Nominee Update',
                    onTap: () {},
                  ),
                  _drawerItem(Icons.group, 'Refer App', onTap: () {}),
                  _drawerItem(Icons.map, 'Map', onTap: () {}),
                  _drawerItem(Icons.explore, 'Discover', onTap: () {}),
                  _drawerItem(Icons.settings, 'Settings', onTap: () {}),
                  _drawerItem(Icons.support_agent, 'Support', onTap: () {}),
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
