import 'package:flutter/material.dart';
import 'package:hrms_app/core/utils/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = _navItems(context);
    final validIndex = currentIndex.clamp(0, items.length - 1);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: validIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      iconSize: 24,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      showSelectedLabels: showLabels,
      showUnselectedLabels: showLabels,
      items: items,
    );
  }

  List<BottomNavigationBarItem> _navItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard, semanticLabel: 'Home'),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.business, semanticLabel: 'Properties'),
        label: 'Properties',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.home, semanticLabel: 'Units'),
        label: 'Units',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people, semanticLabel: 'Tenants'),
        label: 'Tenants',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long, semanticLabel: 'Billing'),
        label: 'Billing',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assessment, semanticLabel: 'Reports'),
        label: 'Reports',
      ),
    ];
  }
}
