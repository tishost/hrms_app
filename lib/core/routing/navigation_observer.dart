import 'package:flutter/material.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🔄 NAVIGATION: Pushed ${route.settings.name}');
    print('   Previous: ${previousRoute?.settings.name}');
    print('   Arguments: ${route.settings.arguments}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('⬅️ NAVIGATION: Popped ${route.settings.name}');
    print('   Previous: ${previousRoute?.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print(
      '🔄 NAVIGATION: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🗑️ NAVIGATION: Removed ${route.settings.name}');
    print('   Previous: ${previousRoute?.settings.name}');
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    print('👆 NAVIGATION: User gesture started on ${route.settings.name}');
  }

  @override
  void didStopUserGesture() {
    print('👆 NAVIGATION: User gesture stopped');
  }
}
