import 'package:flutter/material.dart';
import 'package:hrms_app/core/utils/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  });

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
      iconSize: 18,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 9),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 9,
      ),
      showSelectedLabels: showLabels,
      showUnselectedLabels:
          showLabels, // Show unselected labels only if showLabels is true
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
        label: 'Property',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.home, semanticLabel: 'Units'),
        label: 'Units',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people, semanticLabel: 'Tenants'),
        label: 'Tenant',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long, semanticLabel: 'Billing'),
        label: 'Bill',
      ),
    ];
  }
}
