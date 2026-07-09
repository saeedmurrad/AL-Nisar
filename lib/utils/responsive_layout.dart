import 'package:flutter/material.dart';

/// Shared helpers for adapting layouts to different phone sizes.
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double narrowWidth = 360;

  /// Tablet-and-up breakpoint.
  static const double mediumWidth = 700;

  /// Desktop breakpoint: persistent side navigation replaces the drawer.
  static const double expandedWidth = 1024;

  /// Page content is centered and capped at this width on large screens.
  static const double contentMaxWidth = 1120;

  /// Forms (auth screens, centered dialogs-as-pages) cap at this width.
  static const double formMaxWidth = 460;

  static const double sideNavWidth = 264;

  static bool isMedium(BuildContext context) =>
      screenWidth(context) >= mediumWidth;

  static bool isExpanded(BuildContext context) =>
      screenWidth(context) >= expandedWidth;

  /// Column count for card grids: 2 on phones, 3 on tablets, 4 on desktop.
  static int gridColumns(BuildContext context) {
    final w = screenWidth(context);
    if (w >= expandedWidth) return 4;
    if (w >= mediumWidth) return 3;
    return 2;
  }

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isNarrow(BuildContext context) =>
      screenWidth(context) < narrowWidth;

  static double bottomSheetMaxHeight(
    BuildContext context, {
    double fraction = 0.92,
  }) => screenHeight(context) * fraction;

  /// Wraps bottom-sheet content with keyboard inset, max height, and scroll.
  static Widget scrollableSheet({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  }) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = bottomSheetMaxHeight(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(padding: padding, child: child),
      ),
    );
  }

  /// Taller cells on narrow phones to avoid grid overflow.
  static double booksGridAspectRatio(BuildContext context) {
    final w = screenWidth(context);
    if (w < 340) return 0.50;
    if (w < narrowWidth) return 0.54;
    return 0.58;
  }

  static double homeGridAspectRatio(BuildContext context) {
    final w = screenWidth(context);
    if (w < 340) return 1.0;
    if (w < narrowWidth) return 1.06;
    return 1.12;
  }

  /// Lesson reader page viewport — scales with screen height.
  static double lessonPageViewportHeight(BuildContext context) {
    return (screenHeight(context) * 0.38).clamp(240.0, 460.0);
  }
}
