import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../services/bookmark_service.dart';
import '../services/irshadat_bookmark_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/gold_card.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/theme_palette_picker.dart';
import '../widgets/font_scale_control.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  Future<void> _editName(BuildContext context, String current) async {
    final c = context.c;
    final messenger = ScaffoldMessenger.of(context);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    final controller = TextEditingController(text: current);
    final ok = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.backgroundSurface,
          title: Text(
            'Edit display name',
            style: AppTheme.cormorantGaramond(color: c.textPrimary),
          ),
          content: TextField(
            controller: controller,
            style: AppTheme.lato(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppTheme.lato(color: c.textFaint),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTheme.lato(color: c.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('Save', style: AppTheme.lato(color: c.accentGold)),
            ),
          ],
        );
      },
    );
    if (ok == null || ok.isEmpty) return;
    if (!context.mounted) return;
    try {
      await context.read<AuthProvider>().updateDisplayName(ok);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not update profile',
            style: AppTheme.lato(color: c.textPrimary),
          ),
          backgroundColor: c.backgroundElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final displayName = (profile?.displayName.trim().isNotEmpty == true)
        ? profile!.displayName
        : (auth.user?.displayName ?? 'Member');
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (auth.user?.email ?? '');
    final initials = displayName.isNotEmpty
        ? displayName.trim().substring(0, 1).toUpperCase()
        : 'M';
    final photoUrl = profile?.photoUrl ?? auth.user?.photoURL ?? '';
    final roleLabel = auth.isSuperAdmin
        ? 'Super Admin'
        : (auth.isAdminOrHigher ? 'Admin' : 'User');

    return Scaffold(
      body: Column(
        children: [
          const StandardShellHeader(
            title: 'Profile',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 14),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                GoldCard(
                  backgroundColor: c.backgroundSurface,
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.backgroundElevated,
                          border: Border.all(color: c.accentGold, width: 1.5),
                        ),
                        child: photoUrl.trim().isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Center(
                                        child: Text(
                                          initials,
                                          style: AppTheme.cinzelHeading(
                                            fontSize: 34,
                                            letterSpacing: 1.2,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                      ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: AppTheme.cinzelHeading(
                                    fontSize: 34,
                                    letterSpacing: 1.2,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.cinzelHeading(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _editName(context, displayName),
                            icon: Icon(
                              Icons.edit,
                              color: c.accentGold,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      if (email.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.backgroundElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: c.borderDefault,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<({int pageCount, int bookCount})>(
                  future: BookmarkService().getBookmarkStats(),
                  builder: (context, snap) {
                    final pages = snap.data?.pageCount ?? 0;
                    final books = snap.data?.bookCount ?? 0;
                    return InkWell(
                      onTap: () => context.push('/bookmarks'),
                      borderRadius: BorderRadius.circular(14),
                      child: GoldCard(
                        backgroundColor: c.backgroundSurface,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Bookmarks',
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 14,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pages == 0
                                        ? 'No book pages bookmarked yet'
                                        : '$pages pages bookmarked across $books books',
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: c.accentGold),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Bookmarks',
                  style: TextStyle(
                    color: c.textMuted.o(0.95),
                    letterSpacing: 2.2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TabPill(
                        label: 'Sabaq',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TabPill(
                        label: 'Irshadat',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GoldCard(
                  backgroundColor: c.backgroundSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tab == 0 ? 'Saved Sabaq' : 'Saved Irshadat',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_tab == 0)
                        Text(
                          'Coming soon.',
                          style: TextStyle(color: c.textMuted, fontSize: 12),
                        )
                      else
                        FutureBuilder<({int total, int urdu, int english})>(
                          future: IrshadatBookmarkService().getStats(),
                          builder: (context, snap) {
                            final total = snap.data?.total ?? 0;
                            final urdu = snap.data?.urdu ?? 0;
                            final english = snap.data?.english ?? 0;
                            return InkWell(
                              onTap: total == 0
                                  ? null
                                  : () => context.push('/bookmarks/irshadat'),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    total == 0
                                        ? 'No Irshadat saved yet'
                                        : '$total saved (Urdu: $urdu, English: $english)',
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (total > 0) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Open saved Irshadat',
                                            style: TextStyle(
                                              color: c.accentGold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: c.accentGold,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Appearance',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Color theme',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                const ThemePalettePicker(compact: false),
                const SizedBox(height: 14),
                Text(
                  'Text size',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                const FontScaleControl(),
                if (context.watch<AuthProvider>().isAdminOrHigher) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.push('/admin'),
                    borderRadius: BorderRadius.circular(14),
                    child: GoldCard(
                      backgroundColor: c.backgroundSurface,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Upload and manage app content',
                                  style: TextStyle(
                                    color: c.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: c.accentGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Account',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final router = GoRouter.of(context);
                    await context.read<AuthProvider>().signOut();
                    router.go('/login');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: c.backgroundSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.accentGold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: c.accentGold.o(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: c.accentGold,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sign out',
                          style: AppTheme.lato(
                            color: c.accentGold,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.backgroundElevated : c.backgroundInput,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.accentGold.o(0.55) : c.borderDefault,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.textPrimary : c.textMuted,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
