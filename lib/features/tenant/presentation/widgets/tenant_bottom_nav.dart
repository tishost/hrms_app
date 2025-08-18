import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/providers/language_provider.dart';
import 'package:hrms_app/core/constants/app_strings.dart';

class TenantBottomNav extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TenantBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final code = currentLanguage.code;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.gray,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: AppStrings.getString('dashboard', code),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: AppStrings.getString('billing', code),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: AppStrings.getString('profile', code),
        ),
        BottomNavigationBarItem(
          icon: MoreGlyphIcon(),
          activeIcon: MoreGlyphIcon(),
          label: AppStrings.getString('more', code) ?? 'More',
        ),
      ],
    );
  }
}

class MoreGlyphIcon extends StatelessWidget {
  final double? size;
  const MoreGlyphIcon({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final Color color = IconTheme.of(context).color ?? Colors.black;
    final double iconSize = size ?? (IconTheme.of(context).size ?? 24);
    final double barHeight = iconSize * 0.18;
    final double barWidth = iconSize;
    final double spacing = barHeight * 0.7;
    final BorderRadius radius = BorderRadius.circular(barHeight);

    Widget bar() => Container(
      width: barWidth,
      height: barHeight,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );

    return SizedBox(
      width: barWidth,
      height: barHeight * 3 + spacing * 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          bar(),
          SizedBox(height: spacing),
          bar(),
          SizedBox(height: spacing),
          bar(),
        ],
      ),
    );
  }
}
