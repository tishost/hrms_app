import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routeStack = [];

  List<Route<dynamic>> get routeStack => List.unmodifiable(_routeStack);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.add(route);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _logNavigation('REMOVE', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      _routeStack.add(newRoute);
    }
    _logNavigation('REPLACE', newRoute, oldRoute);
  }

  void _logNavigation(
    String action,
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
  ) {
    debugPrint(
      'Navigation: $action - ${route?.settings.name} (from: ${previousRoute?.settings.name})',
    );
  }

  bool canPop() {
    return _routeStack.length > 1;
  }

  Route<dynamic>? getCurrentRoute() {
    return _routeStack.isNotEmpty ? _routeStack.last : null;
  }

  String? getCurrentRouteName() {
    return getCurrentRoute()?.settings.name;
  }

  void clearStack() {
    _routeStack.clear();
  }

  int get stackDepth => _routeStack.length;
}
