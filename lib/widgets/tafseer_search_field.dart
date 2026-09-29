import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';

/// Search box for the Tafseer index.
class TafseerSearchField extends StatelessWidget {
  const TafseerSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTheme.lato(fontSize: 15, color: c.textPrimary),
      decoration: InputDecoration(
        hintText: 'کوئی لفظ یا آیت تلاش کریں  ·  Search any word or ayah',
        hintStyle: AppTheme.lato(fontSize: 13, color: c.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: c.accentGold, size: 21),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: Icon(Icons.close_rounded, color: c.textMuted, size: 19),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: c.backgroundInput,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusPill),
          borderSide: BorderSide(color: c.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusPill),
          borderSide: BorderSide(color: c.accentGold.o(0.85), width: 1.4),
        ),
      ),
    );
  }
}

/// A selectable pill used for the result-type filters.
class TafseerFilterChip extends StatelessWidget {
  const TafseerFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppLayout.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? c.accentGold.o(0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppLayout.radiusPill),
            border: Border.all(
              color: selected ? c.accentGold : c.borderDefault,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            count == null ? label : '$label  $count',
            style: AppTheme.lato(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c.accentGold : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
