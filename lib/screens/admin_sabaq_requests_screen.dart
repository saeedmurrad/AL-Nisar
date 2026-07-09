import 'package:flutter/material.dart';
import '../models/sabaq_access_request_model.dart';
import '../services/sabaq_access_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class AdminSabaqRequestsScreen extends StatelessWidget {
  const AdminSabaqRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final service = SabaqAccessService();

    return Scaffold(
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'Sabaq Access Requests',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: StreamBuilder<List<SabaqAccessRequestModel>>(
              stream: service.streamPendingRequests(),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending requests',
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
                    final r = list[i];
                    return GoldCard(
                      backgroundColor: c.backgroundSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.titleEn.isEmpty ? 'Sabaq' : r.titleEn,
                            style: AppTheme.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          if (r.titleUr.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                r.titleUr,
                                style: AppTheme.amiriUrdu(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Member: ${r.userName.isNotEmpty ? r.userName : '(name not provided)'}',
                            style: AppTheme.lato(
                              fontSize: 12,
                              color: c.textMuted,
                            ),
                          ),
                          if (r.message.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Message: ${r.message.trim()}',
                              style: AppTheme.lato(
                                fontSize: 12,
                                color: c.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await service.deny(r.id);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade300,
                                    side: BorderSide(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Deny',
                                    style: AppTheme.lato(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await service.approve(
                                      r.id,
                                      userId: r.userId,
                                      sabaqId: r.sabaqId,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.accentGold,
                                    foregroundColor:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? c.backgroundPrimary
                                        : c.textPrimary,
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Allow',
                                    style: AppTheme.lato(
                                      fontWeight: FontWeight.w700,
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}
