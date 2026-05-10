import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/app_role.dart';
import '../auth/auth_provider.dart';
import '../auth/user_profile_model.dart';
import '../services/super_admin_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';

class SuperAdminUsersScreen extends StatelessWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final auth = context.watch<AuthProvider>();
    if (!auth.isSuperAdmin) {
      Future.microtask(() {
        if (context.mounted) context.go('/home');
      });
    }

    final service = SuperAdminService();

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: c.backgroundSurface,
            padding: const EdgeInsets.fromLTRB(10, 18, 16, 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: c.accentGold),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Users',
                      style: AppTheme.cinzelHeading(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfileModel>>(
              stream: service.streamAllUsers(),
              builder: (context, snap) {
                if (snap.hasError) {
                  final uid = auth.user?.uid ?? '(no uid)';
                  final email = auth.user?.email ?? '(no email)';
                  final role = auth.profile?.role.firestoreValue ?? 'user';
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    children: [
                      GoldCard(
                        backgroundColor: c.backgroundSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permission denied',
                              style: AppTheme.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Firestore rules are not recognizing this account as Super Admin.',
                              style: AppTheme.lato(fontSize: 12, color: c.textMuted, height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            Text('uid: $uid', style: AppTheme.lato(fontSize: 12, color: c.textSecondary)),
                            const SizedBox(height: 4),
                            Text('email: $email', style: AppTheme.lato(fontSize: 12, color: c.textSecondary)),
                            const SizedBox(height: 4),
                            Text('role (app): $role', style: AppTheme.lato(fontSize: 12, color: c.textSecondary)),
                            const SizedBox(height: 12),
                            Text(
                              'Fix: In Firestore, open `users/$uid` and set `role` to `super_admin`.',
                              style: AppTheme.lato(fontSize: 12, color: c.textMuted, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return Center(
                    child: Text('No users yet', style: AppTheme.lato(color: c.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final u = list[i];
                    final displayName = u.displayName.trim();
                    return GoldCard(
                      backgroundColor: c.backgroundSurface,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                      : (u.email.isEmpty ? '(no name)' : u.email),
                                  style: AppTheme.lato(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                ),
                                if (displayName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    u.email.isEmpty ? '(no email)' : u.email,
                                    style: AppTheme.lato(
                                      fontSize: 12,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  _roleLabel(u.role),
                                  style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (u.role != AppRole.superAdmin)
                            TextButton(
                              onPressed: () async {
                                final next = u.role == AppRole.admin ? AppRole.user : AppRole.admin;
                                await service.setUserRole(u.uid, next);
                              },
                              child: Text(
                                u.role == AppRole.admin ? 'Demote' : 'Promote',
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
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(AppRole r) {
    switch (r) {
      case AppRole.superAdmin:
        return 'Super Admin';
      case AppRole.admin:
        return 'Admin';
      case AppRole.user:
        return 'User';
    }
  }
}

