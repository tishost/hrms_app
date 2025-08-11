import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/providers/back_button_provider.dart';

class CustomWillPopScope extends ConsumerWidget {
  final Widget child;

  const CustomWillPopScope({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async {
        final backHandler = ref.read(backButtonProvider.notifier);
        final currentRoute = GoRouterState.of(context).matchedLocation;
        print('DEBUG: CustomWillPopScope - Current route: $currentRoute');
        return backHandler.handleBackPress(context, currentRoute);
      },
      child: child,
    );
  }
}
