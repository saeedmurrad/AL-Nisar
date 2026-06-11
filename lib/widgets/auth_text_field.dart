import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lato(
            fontSize: 12,
            color: c.textMuted.o(0.95),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.backgroundInput,
            hintText: hintText,
            hintStyle: AppTheme.lato(fontSize: 13, color: c.textFaint),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.accentGold.o(0.7), width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
