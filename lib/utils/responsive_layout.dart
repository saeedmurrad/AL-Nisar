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
  static const double contentMaxWidth = 1240;

  /// Forms (auth screens, centered dialogs-as-pages) cap at this width.
  static const double formMaxWidth = 460;

  static const double sideNavWidth = 264;

  /// Width of the side navigation when collapsed to icons only.
  static const double sideNavCollapsedWidth = 76;

  /// Height of the desktop top utility bar (collapse toggle + profile menu).
  static const double desktopTopBarHeight = 52;

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

  /// Width of the page content column (accounts for the desktop side nav
  /// and the capped content width applied by the responsive shell).
  static double contentWidth(BuildContext context) {
    final w =
        screenWidth(context) - (isExpanded(context) ? sideNavWidth : 0.0);
    return w > contentMaxWidth ? contentMaxWidth : w;
  }

  /// Book-card grids: fixed cell height derived from the actual cell width
  /// (portrait cover + text block), so cards stay compact and uniform on
  /// every viewport instead of stretching tall on wide screens.
  static SliverGridDelegateWithFixedCrossAxisCount bookGridDelegate(
    BuildContext context, {
    double horizontalPadding = 32,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 14,
  }) {
    final cols = gridColumns(context);
    final cellWidth =
        (contentWidth(context) - horizontalPadding - crossAxisSpacing * (cols - 1)) /
        cols;
    final coverHeight = (cellWidth * 1.05).clamp(150.0, 230.0);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: coverHeight + 102,
    );
  }

  static double homeGridAspectRatio(BuildContext context) {
    final w = screenWidth(context);
    if (w < 340) return 0.94;
    if (w < narrowWidth) return 1.0;
    return 1.06;
  }

  /// Lesson reader page viewport — scales with screen height.
  static double lessonPageViewportHeight(BuildContext context) {
    return (screenHeight(context) * 0.38).clamp(240.0, 460.0);
  }
}
