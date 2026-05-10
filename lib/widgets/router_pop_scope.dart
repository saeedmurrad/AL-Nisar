import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Handles the system back button when [GoRouter] has no imperative stack entry
/// (typical after [GoRouter.go]): falls back to home, then allows the app to exit.
class RouterPopScope extends StatelessWidget {
  const RouterPopScope({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (router.canPop()) {
          router.pop();
          return;
        }
        final path = router.routeInformationProvider.value.uri.path;
        if (path == '/' || path == '/login') {
          SystemNavigator.pop();
          return;
        }
        if (path != '/home') {
          router.go('/home');
          return;
        }
        SystemNavigator.pop();
      },
      child: child ?? const SizedBox.shrink(),
    );
  }
}
