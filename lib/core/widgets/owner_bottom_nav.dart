import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:hrms_app/core/constants/app_strings.dart';

class OwnerBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const OwnerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final code = currentLanguage.code;

    final homeLabel = AppStrings.getString('home', code);
    final propertiesLabel = AppStrings.getString('properties', code);
    final unitsLabel = AppStrings.getString('units', code);
    final tenantsLabel = AppStrings.getString('tenants', code);
    final billingLabel = AppStrings.getString('billing', code);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: homeLabel,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.apartment_rounded,
                label: propertiesLabel,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.home_rounded,
                label: unitsLabel,
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.people_rounded,
                label: tenantsLabel,
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.receipt_rounded,
                label: billingLabel,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.gray,
              size: isSelected ? 22 : 20,
            ),
            if (showLabels) ...[
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.gray,
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
