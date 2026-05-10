import 'package:flutter/material.dart';

extension ColorOpacityX on Color {
  Color o(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    return withValues(alpha: clamped);
  }
}

