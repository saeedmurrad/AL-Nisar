import 'package:flutter/material.dart';

/// Shared helpers for adapting layouts to different phone sizes.
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double narrowWidth = 360;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isNarrow(BuildContext context) =>
      screenWidth(context) < narrowWidth;

  static double bottomSheetMaxHeight(
    BuildContext context, {
    double fraction = 0.92,
  }) =>
      screenHeight(context) * fraction;

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
        child: SingleChildScrollView(
          padding: padding,
          child: child,
        ),
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
