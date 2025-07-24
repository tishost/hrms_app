import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late GoRouter _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  // Basic Navigation Methods
  void push(String route, {Object? extra}) {
    _router.push(route, extra: extra);
  }

  void pushReplacement(String route, {Object? extra}) {
    _router.pushReplacement(route, extra: extra);
  }

  void go(String route, {Object? extra}) {
    _router.go(route, extra: extra);
  }

  void goNamed(String routeName, {Object? extra}) {
    _router.goNamed(routeName, extra: extra);
  }

  void pushNamed(String routeName, {Object? extra}) {
    _router.pushNamed(routeName, extra: extra);
  }

  void pop() {
    if (_router.canPop()) {
      _router.pop();
    }
  }

  void popUntil(String route) {
    _router.pop();
    while (_router.canPop() && _router.location != route) {
      _router.pop();
    }
  }

  // Safe Navigation Methods
  bool canPop() {
    return _router.canPop();
  }

  String get currentLocation => _router.location;

  // Navigation with Parameters
  void pushWithParams(
    String route,
    Map<String, String> params, {
    Object? extra,
  }) {
    String fullRoute = route;
    params.forEach((key, value) {
      fullRoute = fullRoute.replaceAll(':$key', value);
    });
    _router.push(fullRoute, extra: extra);
  }

  void goWithParams(String route, Map<String, String> params, {Object? extra}) {
    String fullRoute = route;
    params.forEach((key, value) {
      fullRoute = fullRoute.replaceAll(':$key', value);
    });
    _router.go(fullRoute, extra: extra);
  }

  // Navigation with Query Parameters
  void pushWithQuery(
    String route,
    Map<String, String> queryParams, {
    Object? extra,
  }) {
    final uri = Uri.parse(route).replace(queryParameters: queryParams);
    _router.push(uri.toString(), extra: extra);
  }

  void goWithQuery(
    String route,
    Map<String, String> queryParams, {
    Object? extra,
  }) {
    final uri = Uri.parse(route).replace(queryParameters: queryParams);
    _router.go(uri.toString(), extra: extra);
  }

  // Navigation with State
  void pushWithState(
    String route,
    Map<String, dynamic> state, {
    Object? extra,
  }) {
    _router.push(route, extra: extra);
  }

  void goWithState(String route, Map<String, dynamic> state, {Object? extra}) {
    _router.go(route, extra: extra);
  }

  // Navigation Guards
  bool canNavigateTo(String route) {
    // Add your navigation guard logic here
    return true;
  }

  // Navigation History
  List<String> get navigationHistory {
    // This would need to be implemented based on your router's history
    return [];
  }

  // Clear Navigation History
  void clearHistory() {
    // This would need to be implemented based on your router's capabilities
  }

  // Navigation with Animation
  void pushWithAnimation(String route, {Object? extra}) {
    _router.push(route, extra: extra);
  }

  // Navigation with Custom Transition
  void pushWithCustomTransition(String route, {Object? extra}) {
    _router.push(route, extra: extra);
  }

  // Navigation with Callback
  void pushWithCallback(
    String route,
    VoidCallback onComplete, {
    Object? extra,
  }) {
    _router.push(route, extra: extra);
    // Note: This is a simplified implementation
    // In a real app, you might want to use a more sophisticated approach
  }

  // Navigation with Error Handling
  void safePush(String route, {Object? extra}) {
    try {
      _router.push(route, extra: extra);
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Handle navigation error
    }
  }

  void safeGo(String route, {Object? extra}) {
    try {
      _router.go(route, extra: extra);
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Handle navigation error
    }
  }

  // Navigation with Loading
  void pushWithLoading(String route, {Object? extra}) {
    // Show loading indicator
    _router.push(route, extra: extra);
    // Hide loading indicator
  }

  // Navigation with Confirmation
  void pushWithConfirmation(String route, String message, {Object? extra}) {
    // Show confirmation dialog
    _router.push(route, extra: extra);
  }

  // Navigation with Validation
  void pushWithValidation(
    String route,
    bool Function() validator, {
    Object? extra,
  }) {
    if (validator()) {
      _router.push(route, extra: extra);
    }
  }
}
