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

class _AdminNotificationsList extends StatefulWidget {
  const _AdminNotificationsList({required this.colors});

  final AppThemeColors colors;

  @override
  State<_AdminNotificationsList> createState() => _AdminNotificationsListState();
}

class _AdminNotificationsListState extends State<_AdminNotificationsList> {
  final _service = AdminNotificationsService();
  final Set<String> _markingIds = {};

  @override
  void initState() {
    super.initState();
    _service.pruneResolvedSabaqRequestNotifications();
  }

  Future<void> _markRead(String id) async {
    setState(() => _markingIds.add(id));
    try {
      await _service.markAsRead(id);
    } finally {
      if (mounted) setState(() => _markingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _service.streamRecent(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Could not load notifications',
              style: AppTheme.lato(color: widget.colors.textMuted),
            ),
          );
        }
        final list = snap.data ?? const [];
        if (snap.connectionState == ConnectionState.waiting && list.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: widget.colors.accentGold),
          );
        }
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: AppTheme.lato(color: widget.colors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = list[i];
            final marking = _markingIds.contains(n.id);
            return GoldCard(
              backgroundColor: widget.colors.backgroundSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: AppTheme.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: widget.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.body,
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: widget.colors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: marking
                            ? null
                            : () => context.push('/admin/sabaq-requests'),
                        child: Text(
                          'Open Sabaq requests',
                          style: AppTheme.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.colors.accentGold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (marking)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.colors.accentGold,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () => _markRead(n.id),
                          child: Text(
                            'Mark as read',
                            style: AppTheme.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.colors.textMuted,
                            ),
                          ),
                        ),
                    ],
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

class _MemberNotificationsList extends StatefulWidget {
  const _MemberNotificationsList({
    required this.colors,
    required this.userId,
  });

  final AppThemeColors colors;
  final String userId;

  @override
  State<_MemberNotificationsList> createState() => _MemberNotificationsListState();
}

class _MemberNotificationsListState extends State<_MemberNotificationsList> {
  final _service = UserNotificationsService();
  final Set<String> _markingIds = {};

  Future<void> _markRead(String id) async {
    setState(() => _markingIds.add(id));
    try {
      await _service.markAsRead(widget.userId, id);
    } finally {
      if (mounted) setState(() => _markingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _service.streamForUser(widget.userId),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: AppTheme.lato(color: widget.colors.textMuted),
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
            final showNewsLink =
                n.type == 'news_published' && (n.newsId?.isNotEmpty ?? false);
            final showEventLink =
                n.type == 'event_published' && (n.eventId?.isNotEmpty ?? false);
            final showContentLink = showSabaqLink || showNewsLink || showEventLink;
            final marking = _markingIds.contains(n.id);
            final isUnread = !n.read;
            return GoldCard(
              backgroundColor: widget.colors.backgroundSurface,
              child: Opacity(
                opacity: isUnread ? 1 : 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: AppTheme.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: widget.colors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 8),
                            decoration: BoxDecoration(
                              color: widget.colors.accentGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      n.body,
                      style: AppTheme.lato(
                        fontSize: 12,
                        color: widget.colors.textMuted,
                        height: 1.35,
                      ),
                    ),
                    if (showContentLink || isUnread) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (showSabaqLink)
                            TextButton(
                              onPressed: () => context.go('/sabaq'),
                              child: Text(
                                'View Sabaq',
                                style: AppTheme.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.colors.accentGold,
                                ),
                              ),
                            ),
                          if (showNewsLink)
                            TextButton(
                              onPressed: () => context.go(
                                '/news-events/news-detail?id=${n.newsId}',
                              ),
                              child: Text(
                                'View news',
                                style: AppTheme.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.colors.accentGold,
                                ),
                              ),
                            ),
                          if (showEventLink)
                            TextButton(
                              onPressed: () => context.go(
                                '/news-events/event-detail?id=${n.eventId}',
                              ),
                              child: Text(
                                'View event',
                                style: AppTheme.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.colors.accentGold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          if (isUnread)
                            if (marking)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: widget.colors.accentGold,
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () => _markRead(n.id),
                                child: Text(
                                  'Mark as read',
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: widget.colors.textMuted,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
