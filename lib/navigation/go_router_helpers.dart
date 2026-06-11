import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Result of the app-wide Android / system back policy.
enum SystemBackResult {
  didPop,
  navigatedHome,
  exitedApp,
  needsHomeDoubleBack,
}

/// Matches [popOrGoHome] but is async and tries [GoRouterDelegate.popRoute] first
/// so nested navigators behave like the visible Back button.
Future<SystemBackResult> handleSystemBack({
  required GoRouter router,
  required bool isAuthenticated,
}) async {
  if (await router.routerDelegate.popRoute()) {
    return SystemBackResult.didPop;
  }
  if (router.canPop()) {
    router.pop();
    return SystemBackResult.didPop;
  }

  var path = router.routeInformationProvider.value.uri.path;
  if (path.isEmpty) path = '/';

  if (path == '/') {
    if (isAuthenticated) {
      router.go('/home');
      return SystemBackResult.navigatedHome;
    }
    SystemNavigator.pop();
    return SystemBackResult.exitedApp;
  }

  if (path == '/login') {
    SystemNavigator.pop();
    return SystemBackResult.exitedApp;
  }

  if (path == '/signup' || path == '/forgot-password') {
    router.go('/login');
    return SystemBackResult.navigatedHome;
  }

  if (path == '/home') {
    return SystemBackResult.needsHomeDoubleBack;
  }

  router.go('/home');
  return SystemBackResult.navigatedHome;
}

/// Toolbar / explicit Back: pop nested route if possible, else open dashboard.
void popOrGoHome(BuildContext context) {
  final router = GoRouter.of(context);
  unawaited(() async {
    if (await router.routerDelegate.popRoute()) return;
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/home');
  }());
}

/// Replaces the current stack with the main dashboard.
void goAppHome(BuildContext context) {
  GoRouter.of(context).go('/home');
}
