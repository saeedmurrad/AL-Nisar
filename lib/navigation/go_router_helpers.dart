import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pops the route stack when possible; otherwise opens the main dashboard.
void popOrGoHome(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go('/home');
  }
}

/// Replaces the current stack with the main dashboard.
void goAppHome(BuildContext context) {
  GoRouter.of(context).go('/home');
}
