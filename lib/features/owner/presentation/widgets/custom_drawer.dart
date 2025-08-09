import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:hrms_app/core/constants/app_strings.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  final Function()? onLogout;

  const CustomDrawer({super.key, this.onLogout});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final languageNotifier = ref.watch(languageProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          top: true,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Additional top spacing
                SizedBox(height: 5),
                // Drawer title (left aligned)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 5.0,
                    bottom: 5.0,
                    left: 20.0,
                    right: 20.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      languageNotifier.getString('menu') ?? 'Menu',
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
                // Language Toggle Button (Compact)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _toggleLanguage(languageNotifier);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Text(
                                currentLanguage.code == 'en'
                                    ? 'English'
                                    : 'বাংলা',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Menu items
                Expanded(
                  child: ListView(
                    children: [
                      _drawerItem(
                        Icons.home,
                        languageNotifier.getString('home') ?? 'Home',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/dashboard');
                        },
                      ),
                      _drawerItem(
                        Icons.business,
                        languageNotifier.getString('properties') ??
                            'Properties',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/properties');
                        },
                      ),
                      _drawerItem(
                        Icons.home_work,
                        languageNotifier.getString('units') ?? 'Units',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/units');
                        },
                      ),
                      _drawerItem(
                        Icons.people,
                        languageNotifier.getString('tenants') ?? 'Tenants',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/tenants');
                        },
                      ),
                      _drawerItem(
                        Icons.receipt_long,
                        languageNotifier.getString('checkout_records') ??
                            'Checkout Records',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/checkouts');
                        },
                      ),
                      _drawerItem(
                        Icons.attach_money,
                        languageNotifier.getString('billing') ?? 'Billing',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/billing');
                        },
                      ),
                      _drawerItem(
                        Icons.workspace_premium,
                        languageNotifier.getString('subscription') ??
                            'Subscription',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/subscription-center');
                        },
                      ),
                      _drawerItem(
                        Icons.rocket_launch,
                        languageNotifier.getString('subscription_plans') ??
                            'Subscription Plans',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/subscription-plans');
                        },
                      ),
                      _drawerItem(
                        Icons.assessment,
                        languageNotifier.getString('reports') ?? 'Reports',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/reports');
                        },
                      ),
                      _drawerItem(
                        Icons.person,
                        languageNotifier.getString('profile') ?? 'Profile',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/profile');
                        },
                      ),
                      _drawerItem(
                        Icons.notifications,
                        languageNotifier.getString('notifications') ??
                            'Notifications',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/notifications');
                        },
                      ),

                      _drawerItem(
                        Icons.settings,
                        languageNotifier.getString('settings') ?? 'Settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/settings');
                        },
                      ),
                      _drawerItem(
                        Icons.help_outline,
                        languageNotifier.getString('help_support') ??
                            'Help & Support',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/help');
                        },
                      ),
                      _drawerItem(
                        Icons.info_outline,
                        languageNotifier.getString('about') ?? 'About',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/about');
                        },
                      ),
                    ],
                  ),
                ),
                Divider(),
                // Log Out button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                      languageNotifier.getString('log_out') ?? 'Log Out',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed:
                        widget.onLogout ??
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
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Language',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text('English'),
                onTap: () {
                  Navigator.of(context).pop();
                  _changeLanguage(context, 'en');
                },
              ),
              ListTile(
                leading: Text('🇧🇩', style: TextStyle(fontSize: 24)),
                title: Text('বাংলা'),
                onTap: () {
                  Navigator.of(context).pop();
                  _changeLanguage(context, 'bn');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _toggleLanguage(LanguageNotifier languageNotifier) async {
    final newLanguage = languageNotifier.currentLanguageCode == 'en'
        ? 'bn'
        : 'en';
    await languageNotifier.changeLanguage(newLanguage);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLanguage == 'en'
                ? 'Language changed to English'
                : 'ভাষা বাংলায় পরিবর্তন করা হয়েছে',
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          languageCode == 'en'
              ? 'Language changed to English'
              : 'ভাষা বাংলায় পরিবর্তন করা হয়েছে',
        ),
        backgroundColor: AppColors.primary,
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
