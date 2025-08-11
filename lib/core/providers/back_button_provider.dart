import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackButtonState {
  final DateTime? lastBackPressTime;

  BackButtonState({this.lastBackPressTime});
}

class BackButtonNotifier extends StateNotifier<BackButtonState> {
  BackButtonNotifier() : super(BackButtonState());

  Future<bool> handleBackPress(BuildContext context, String currentPath) async {
    print('DEBUG: BackButtonNotifier - Handling back press for: $currentPath');
    const protectedRoutes = ['/dashboard', '/tenant-dashboard'];

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return false;
    }

    if (protectedRoutes.contains(currentPath)) {
      final now = DateTime.now();
      if (state.lastBackPressTime == null ||
          now.difference(state.lastBackPressTime!) >
              const Duration(seconds: 2)) {
        state = BackButtonState(lastBackPressTime: now);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
      return true;
    }
    return true;
  }
}

final backButtonProvider =
    StateNotifierProvider<BackButtonNotifier, BackButtonState>(
      (ref) => BackButtonNotifier(),
    );
