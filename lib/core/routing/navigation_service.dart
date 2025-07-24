import 'package:flutter/material.dart';
import 'package:hrms_app/core/routing/app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Safe navigation methods
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) async {
    try {
      return await navigatorKey.currentState?.pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      print('Navigation Error: $e');
      return null;
    }
  }

  static Future<T?> pushReplacementNamed<T>(
    String routeName, {
    Object? arguments,
  }) async {
    try {
      return await navigatorKey.currentState?.pushReplacementNamed<T, void>(
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      print('Navigation Error: $e');
      return null;
    }
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    try {
      return await navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(
        routeName,
        predicate,
        arguments: arguments,
      );
    } catch (e) {
      print('Navigation Error: $e');
      return null;
    }
  }

  static void pop<T>([T? result]) {
    try {
      if (navigatorKey.currentState?.canPop() == true) {
        navigatorKey.currentState?.pop<T>(result);
      } else {
        print('Cannot pop: Navigation stack is empty');
      }
    } catch (e) {
      print('Navigation Error: $e');
    }
  }

  // Specific navigation methods
  static void goToDashboard() {
    pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
  }

  static void goToLogin() {
    pushReplacementNamed(AppRoutes.login);
  }

  static void goToSignup() {
    pushReplacementNamed(AppRoutes.signup);
  }

  static void goToTenants() {
    pushNamed(AppRoutes.tenants);
  }

  static void goToProperties() {
    pushNamed(AppRoutes.properties);
  }

  static void goToUnits() {
    pushNamed(AppRoutes.units);
  }

  static void goToBilling() {
    pushNamed(AppRoutes.billing);
  }

  static void goToProfile() {
    pushNamed(AppRoutes.profile);
  }

  // Safe back navigation
  static void goBack() {
    try {
      if (navigatorKey.currentState?.canPop() == true) {
        navigatorKey.currentState?.pop();
      } else {
        // Fallback to dashboard if cannot pop
        goToDashboard();
      }
    } catch (e) {
      print('Back Navigation Error: $e');
      goToDashboard();
    }
  }
}
