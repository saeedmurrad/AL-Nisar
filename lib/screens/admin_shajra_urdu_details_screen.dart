import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/shajra_entry_model.dart';
import '../services/shajra_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class AdminShajraUrduDetailsScreen extends StatefulWidget {
  const AdminShajraUrduDetailsScreen({super.key});

  @override
  State<AdminShajraUrduDetailsScreen> createState() =>
      _AdminShajraUrduDetailsScreenState();
}

class _AdminShajraUrduDetailsScreenState
    extends State<AdminShajraUrduDetailsScreen> {
  final _service = ShajraService();
  bool _loading = true;
  Object? _error;
  List<ShajraEntryModel> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchUrduShajraList();
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'Add Urdu Shajra Details',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.accentGold))
                : _error != null
                ? _ErrorState(onRetry: _load)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => context.push(
                            '/admin/shajra-urdu/upload',
                            extra: AdminShajraUrduUploadArgs(entry: e),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: GoldCard(
                            backgroundColor: c.backgroundSurface,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: c.backgroundElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: c.borderDefault,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${e.number}',
                                    style: AppTheme.lato(
                                      fontWeight: FontWeight.w800,
                                      color: c.accentGold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      e.listDisplayName,
                                      style: AppTheme.amiriUrdu(
                                        fontSize: 16,
                                        height: 1.6,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: c.accentGold),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load Urdu list',
              style: AppTheme.cormorantGaramond(
                fontSize: 18,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accentGold,
                side: BorderSide(color: c.accentGold),
              ),
              child: Text('Try Again', style: AppTheme.lato()),
            ),
          ],
        ),
      ),
    );
  }
}
