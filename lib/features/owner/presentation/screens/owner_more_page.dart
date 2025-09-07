import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/providers/app_providers.dart';
import 'package:hrms_app/core/providers/language_provider.dart';

class OwnerMorePage extends ConsumerStatefulWidget {
  const OwnerMorePage({super.key});

  @override
  ConsumerState<OwnerMorePage> createState() => _OwnerMorePageState();
}

class _OwnerMorePageState extends ConsumerState<OwnerMorePage> {
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
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            _buildLanguageCard(),
            SizedBox(height: 20),
            _buildMenuGridSection(),
            SizedBox(height: 20),
            _buildSubscriptionGridSection(),
            SizedBox(height: 20),
            _buildOthersGridSection(),
            SizedBox(height: 20),
            _buildSignOutSection(),
            SizedBox(height: 20),
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
                  title: 'Billing',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => context.go('/billing'),
                ),
                _buildGridMenuItem(
                  title: 'Reports',
                  icon: Icons.assessment_outlined,
                  onTap: () => context.go('/reports'),
                ),
                _buildGridMenuItem(
                  title: 'Checkout List',
                  icon: Icons.logout_outlined,
                  onTap: () => context.go('/checkout-list'),
                ),
                _buildGridMenuItem(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => context.go('/settings'),
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

  Widget _buildSubscriptionGridSection() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription',
              style: TextStyle(fontSize: 20, color: AppColors.text),
            ),
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
                  title: 'Center',
                  icon: Icons.workspace_premium_outlined,
                  onTap: () => context.go('/subscription-center'),
                ),
                _buildGridMenuItem(
                  title: 'Plans',
                  icon: Icons.upgrade,
                  onTap: () => context.go('/subscription-plans'),
                ),
                _buildGridMenuItem(
                  title: 'Usage & Limits',
                  icon: Icons.speed,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Usage & limits coming soon!'),
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

  Widget _buildOthersGridSection() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Others',
              style: TextStyle(fontSize: 20, color: AppColors.text),
            ),
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
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () => context.go('/notifications'),
                ),
                _buildGridMenuItem(
                  title: 'Help & Support',
                  icon: Icons.help_outline,
                  onTap: () => context.go('/help'),
                ),
                _buildGridMenuItem(
                  title: 'About',
                  icon: Icons.info_outline,
                  onTap: () => context.go('/about'),
                ),
                _buildGridMenuItem(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutSection() {
    return GestureDetector(
      onTap: () async {
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Sign Out'),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await ref.read(authStateProvider.notifier).logout();
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
    final currentLanguage = ref.watch(languageProvider);
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
            GestureDetector(
              onTap: () {
                _toggleLanguage();
              },
              child: Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: currentLanguage.code == 'bn'
                      ? AppColors.primary
                      : Colors.grey[300],
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 200),
                      left: currentLanguage.code == 'bn' ? 30 : 2,
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
                            currentLanguage.code == 'bn' ? 'বাং' : 'EN',
                            style: TextStyle(
                              color: currentLanguage.code == 'bn'
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

  void _toggleLanguage() async {
    final languageNotifier = ref.read(languageProvider.notifier);
    final currentLanguage = ref.read(languageProvider);

    final newLanguage = currentLanguage.code == 'en' ? 'bn' : 'en';
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
}
