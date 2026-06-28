import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../services/admin_notifications_service.dart';
import '../services/user_notifications_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isSuperAdmin) {
        AdminNotificationsService().pruneResolvedSabaqRequestNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return _BellIcon(colors: c, count: 0, onTap: widget.onTap);
    }

    final stream = auth.isSuperAdmin
        ? AdminNotificationsService().streamUnreadCount()
        : UserNotificationsService().streamUnreadCountForUser(auth.user!.uid);

    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return _BellIcon(colors: c, count: count, onTap: widget.onTap);
      },
    );
  }
}

class _BellIcon extends StatelessWidget {
  const _BellIcon({
    required this.colors,
    required this.count,
    required this.onTap,
  });

  final AppThemeColors colors;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.backgroundElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.borderDefault,
                width: 0.5,
              ),
            ),
            child: SvgPicture.string(
              _bellSvg,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                colors.accentGold,
                BlendMode.srcIn,
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentGold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.backgroundSurface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTheme.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.backgroundPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _bellSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 22a2.5 2.5 0 0 0 2.45-2h-4.9A2.5 2.5 0 0 0 12 22Z" fill="currentColor"/><path d="M18 16v-5a6 6 0 1 0-12 0v5l-2 2v1h16v-1l-2-2Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>';
