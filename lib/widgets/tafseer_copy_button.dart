import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

/// Copies the current ruku's text. Rendered only for Super Admins.
///
/// Takes the role decision as a plain bool rather than reading AuthProvider
/// itself, so the gating is directly testable and the screen stays the only
/// place that talks to auth.
///
/// It must also be its own widget rather than an inline subtree: the shell
/// header re-themes its children to the on-emerald chrome tokens, and only a
/// widget that reads `context.c` in its *own* build picks that up.
class TafseerCopyButton extends StatelessWidget {
  const TafseerCopyButton({
    super.key,
    required this.isSuperAdmin,
    required this.onCopy,
  });

  final bool isSuperAdmin;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    if (!isSuperAdmin) return const SizedBox.shrink();
    return IconButton(
      onPressed: onCopy,
      tooltip: 'Copy ruku text',
      icon: Icon(Icons.copy_all_outlined, color: context.c.accentGold, size: 22),
    );
  }
}
