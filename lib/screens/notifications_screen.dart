import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../services/admin_notifications_service.dart';
import '../services/user_notifications_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/standard_shell_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          const StandardShellHeader(
            title: 'Notifications',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: auth.isSuperAdmin
                ? _AdminNotificationsList(colors: c)
                : auth.isAuthenticated
                    ? _MemberNotificationsList(
                        colors: c,
                        userId: auth.user!.uid,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Sign in to view notifications.',
                            textAlign: TextAlign.center,
                            style: AppTheme.lato(color: c.textMuted, fontSize: 14),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotificationsList extends StatelessWidget {
  const _AdminNotificationsList({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final service = AdminNotificationsService();
    return StreamBuilder(
      stream: service.streamRecent(),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: AppTheme.lato(color: colors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = list[i];
            return GoldCard(
              backgroundColor: colors.backgroundSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: AppTheme.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.body,
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push('/admin/sabaq-requests'),
                    child: Text(
                      'Open Sabaq requests',
                      style: AppTheme.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MemberNotificationsList extends StatelessWidget {
  const _MemberNotificationsList({
    required this.colors,
    required this.userId,
  });

  final AppThemeColors colors;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final service = UserNotificationsService();
    return StreamBuilder(
      stream: service.streamForUser(userId),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: AppTheme.lato(color: colors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = list[i];
            final showSabaqLink = n.type == 'sabaq_approved';
            return GoldCard(
              backgroundColor: colors.backgroundSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: AppTheme.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.body,
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  if (showSabaqLink) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/sabaq'),
                      child: Text(
                        'View Sabaq',
                        style: AppTheme.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.accentGold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
