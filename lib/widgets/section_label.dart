import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      label.toUpperCase(),
      style: AppTheme.sectionCaption(color: c.textMuted),
    );
  }
}
