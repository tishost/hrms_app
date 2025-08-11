import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Navigation state provider
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState());

  void pushRoute(String route) {
    state = state.copyWith(
      currentRoute: route,
      navigationHistory: [...state.navigationHistory, route],
    );
  }

  void popRoute() {
    if (state.navigationHistory.length > 1) {
      final newHistory = List<String>.from(state.navigationHistory);
      newHistory.removeLast();
      final previousRoute = newHistory.last;
      
      state = state.copyWith(
        currentRoute: previousRoute,
        navigationHistory: newHistory,
      );
    }
  }

  void goToRoute(String route) {
    state = state.copyWith(
      currentRoute: route,
      navigationHistory: [...state.navigationHistory, route],
    );
  }

  void replaceRoute(String route) {
    if (state.navigationHistory.isNotEmpty) {
      final newHistory = List<String>.from(state.navigationHistory);
      newHistory[newHistory.length - 1] = route;
      
      state = state.copyWith(
        currentRoute: route,
        navigationHistory: newHistory,
      );
    }
  }

  bool canPop() {
    return state.navigationHistory.length > 1;
  }

  String? getPreviousRoute() {
    if (state.navigationHistory.length > 1) {
      return state.navigationHistory[state.navigationHistory.length - 2];
    }
    return null;
  }

  void resetToRoute(String route) {
    state = state.copyWith(
      currentRoute: route,
      navigationHistory: [route],
    );
  }
}

class NavigationState {
  final String currentRoute;
  final List<String> navigationHistory;

  NavigationState({
    this.currentRoute = '/',
    this.navigationHistory = const ['/'],
  });

  NavigationState copyWith({
    String? currentRoute,
    List<String>? navigationHistory,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      navigationHistory: navigationHistory ?? this.navigationHistory,
    );
  }
}

// Provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

// Navigation service provider
final navigationServiceProvider = Provider<NavigationService>((ref) {
  final navigationNotifier = ref.read(navigationProvider.notifier);
  return NavigationService(navigationNotifier);
});

class NavigationService {
  final NavigationNotifier _navigationNotifier;

  NavigationService(this._navigationNotifier);

  void pushRoute(String route) => _navigationNotifier.pushRoute(route);
  void popRoute() => _navigationNotifier.popRoute();
  void goToRoute(String route) => _navigationNotifier.goToRoute(route);
  void replaceRoute(String route) => _navigationNotifier.replaceRoute(route);
  bool canPop() => _navigationNotifier.canPop();
  String? getPreviousRoute() => _navigationNotifier.getPreviousRoute();
  void resetToRoute(String route) => _navigationNotifier.resetToRoute(route);
}
