import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../navigation/go_router_helpers.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

/// Handles the Android / predictive system back button for [GoRouter].
///
/// Behavior matches [popOrGoHome] / [StandardShellHeader] back: pop nested routes
/// first, then go to `/home` from any non-root tab screen; on `/home`, double-tap
/// within 2s to exit.
class RouterPopScope extends StatefulWidget {
  const RouterPopScope({
    super.key,
    required this.router,
    required this.isAuthenticated,
    required this.child,
  });

  final GoRouter router;
  final bool isAuthenticated;
  final Widget? child;

  @override
  State<RouterPopScope> createState() => _RouterPopScopeState();
}

class _RouterPopScopeState extends State<RouterPopScope> {
  DateTime? _firstBackToExit;

  Future<void> _handleSystemBack() async {
    if (!mounted) return;

    final result = await handleSystemBack(
      router: widget.router,
      isAuthenticated: widget.isAuthenticated,
    );

    switch (result) {
      case SystemBackResult.didPop:
      case SystemBackResult.navigatedHome:
        _firstBackToExit = null;
        return;
      case SystemBackResult.exitedApp:
        return;
      case SystemBackResult.needsHomeDoubleBack:
        break;
    }

    final now = DateTime.now();
    if (_firstBackToExit != null &&
        now.difference(_firstBackToExit!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _firstBackToExit = now;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final c = context.c;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Press back again to exit',
          style: AppTheme.lato(color: c.textPrimary),
        ),
        backgroundColor: c.backgroundElevated,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        unawaited(_handleSystemBack());
      },
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
