import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../services/admin_notifications_service.dart';
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
    final service = AdminNotificationsService();

    return Scaffold(
      body: Column(
        children: [
          const StandardShellHeader(
            title: 'Notifications',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: auth.isSuperAdmin
                ? StreamBuilder(
                    stream: service.streamRecent(),
                    builder: (context, snap) {
                      final list = snap.data ?? const [];
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'No notifications yet',
                            style: AppTheme.lato(color: c.textMuted),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = list[i];
                          return GoldCard(
                            backgroundColor: c.backgroundSurface,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: AppTheme.lato(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  n.body,
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    color: c.textMuted,
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
                                      color: c.accentGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No notifications to show.',
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
