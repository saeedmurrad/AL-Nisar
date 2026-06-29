import 'package:flutter/material.dart';

/// Shared spacing, radius, and shell padding tokens.
class AppLayout {
  AppLayout._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;

  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 14;
  static const double radiusPill = 999;

  static const EdgeInsets shellPadding =
      EdgeInsets.fromLTRB(4, 18, 16, 12);

  static const EdgeInsets screenPadding =
      EdgeInsets.fromLTRB(16, 14, 16, 16);

  static BorderRadius get cardRadius => BorderRadius.circular(radiusLg);
}
