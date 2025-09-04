import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackButtonState {
  final DateTime? lastBackPressTime;
  final bool isViewingInvoice;

  BackButtonState({this.lastBackPressTime, this.isViewingInvoice = false});
}

class BackButtonNotifier extends StateNotifier<BackButtonState> {
  BackButtonNotifier() : super(BackButtonState());

  void setViewingInvoice(bool viewing) {
    state = BackButtonState(
      lastBackPressTime: state.lastBackPressTime,
      isViewingInvoice: viewing,
    );
  }

  Future<bool> handleBackPress(BuildContext context, String currentPath) async {
    print('DEBUG: BackButtonNotifier - Handling back press for: $currentPath');
    const protectedRoutes = ['/dashboard', '/tenant-dashboard'];

    if (state.isViewingInvoice) {
      print(
        '🔵 BackButton: Handling back from invoice - going to billing page',
      );
      Navigator.of(context).pop();
      setViewingInvoice(false);
      return true; // Prevent default system back behavior
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true; // Prevent default system back behavior
    }

    if (protectedRoutes.contains(currentPath)) {
      final now = DateTime.now();
      if (state.lastBackPressTime == null ||
          now.difference(state.lastBackPressTime!) >
              const Duration(seconds: 2)) {
        state = BackButtonState(
          lastBackPressTime: now,
          isViewingInvoice: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return true; // Prevent default system back behavior
      }
      return false; // Allow system exit (double-tap confirmed)
    }
    return false; // Allow default system back behavior
  }
}

final backButtonProvider =
    StateNotifierProvider<BackButtonNotifier, BackButtonState>(
      (ref) => BackButtonNotifier(),
    );
