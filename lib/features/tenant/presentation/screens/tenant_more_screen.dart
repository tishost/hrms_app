import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/providers/app_providers.dart';

class TenantMoreScreen extends ConsumerStatefulWidget {
  const TenantMoreScreen({super.key});

  @override
  ConsumerState<TenantMoreScreen> createState() => _TenantMoreScreenState();
}

class _TenantMoreScreenState extends ConsumerState<TenantMoreScreen> {
  bool _isBengali = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'More',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/tenant/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            // Language Switch Card
            _buildLanguageCard(),
            SizedBox(height: 20),

            // Menu Grid Section
            _buildMenuGridSection(),
            SizedBox(height: 20),

            // Sign Out Section
            _buildSignOutSection(),
            SizedBox(height: 20),

            // Version Info
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGridSection() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('More', style: TextStyle(fontSize: 20, color: AppColors.text)),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
              children: [
                _buildGridMenuItem(
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  onTap: () => context.go('/tenant/dashboard'),
                ),
                _buildGridMenuItem(
                  title: 'Billing',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.go('/tenant/billing'),
                ),
                _buildGridMenuItem(
                  title: 'Profile',
                  icon: Icons.person_outline,
                  onTap: () => context.go('/tenant/profile'),
                ),
                _buildGridMenuItem(
                  title: 'Rent Agreement',
                  icon: Icons.description_outlined,
                  onTap: () => context.go('/tenant/rent-agreement'),
                ),
                _buildGridMenuItem(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Settings coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                _buildGridMenuItem(
                  title: 'Help',
                  icon: Icons.help_outline,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Help & Support coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection() {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Sign Out'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          // Use the auth state provider to properly logout and update state
          await ref.read(authStateProvider.notifier).logout();
          if (!mounted) return;

          // The redirect logic in main.dart will automatically handle navigation
          // No need for manual navigation as the auth state change will trigger redirect
        }
      },
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.power_settings_new,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Spacer(),
              // Sign Out Button
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Center(
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Text(
              'Language',
              style: TextStyle(fontSize: 18, color: AppColors.text),
            ),
            Spacer(),
            // Language Toggle Switch
            GestureDetector(
              onTap: () {
                setState(() {
                  _isBengali = !_isBengali;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isBengali
                          ? 'Language changed to বাংলা'
                          : 'Language changed to English',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _isBengali ? AppColors.primary : Colors.grey[300],
                ),
                child: Stack(
                  children: [
                    // Toggle Track
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 200),
                      left: _isBengali ? 30 : 2,
                      top: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isBengali ? 'বাং' : 'EN',
                            style: TextStyle(
                              color: _isBengali
                                  ? AppColors.primary
                                  : Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
