import 'package:flutter/material.dart';

import '../models/social_links_config.dart';
import '../services/social_links_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class AdminSocialLinksScreen extends StatefulWidget {
  const AdminSocialLinksScreen({super.key});

  @override
  State<AdminSocialLinksScreen> createState() => _AdminSocialLinksScreenState();
}

class _AdminSocialLinksScreenState extends State<AdminSocialLinksScreen> {
  final _service = SocialLinksService();
  final _facebookPage = TextEditingController();
  final _youtubeChannel = TextEditingController();
  final _facebookLive = TextEditingController();
  bool _isFacebookLive = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _facebookPage.dispose();
    _youtubeChannel.dispose();
    _facebookLive.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final config = await _service.loadConfig();
    if (!mounted) return;
    _facebookPage.text = config.facebookPageUrl;
    _youtubeChannel.text = config.youtubeChannelUrl;
    _facebookLive.text = config.facebookLiveUrl;
    setState(() {
      _isFacebookLive = config.isFacebookLive;
      _loading = false;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _save() async {
    final fb = _facebookPage.text.trim();
    final yt = _youtubeChannel.text.trim();
    if (fb.isEmpty || yt.isEmpty) {
      _snack('Facebook and YouTube URLs are required');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveConfig(
        SocialLinksConfig(
          facebookPageUrl: fb,
          youtubeChannelUrl: yt,
          facebookLiveUrl: _facebookLive.text.trim(),
          isFacebookLive: _isFacebookLive,
        ),
      );
      if (!mounted) return;
      _snack('Social links saved');
    } catch (_) {
      if (!mounted) return;
      _snack('Could not save social links');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'Social Links',
            padding: EdgeInsets.fromLTRB(4, 18, 8, 12),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Home screen buttons for Facebook and YouTube. Turn on Go Live when streaming on Facebook.',
                        style: AppTheme.lato(fontSize: 13, color: c.textMuted, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      GoldCard(
                        backgroundColor: c.backgroundInput,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Field(
                              label: 'Facebook Page URL',
                              controller: _facebookPage,
                              hint: 'https://www.facebook.com/SufiNisarAhmad',
                            ),
                            const SizedBox(height: 14),
                            _Field(
                              label: 'YouTube Channel URL',
                              controller: _youtubeChannel,
                              hint: 'https://www.youtube.com/@sufinisarahmad159',
                            ),
                            const SizedBox(height: 14),
                            _Field(
                              label: 'Facebook Live URL (when streaming)',
                              controller: _facebookLive,
                              hint: 'Paste live video link when on air',
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Go Live on Facebook',
                                style: AppTheme.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Shows “Watch Live on Facebook” on Home',
                                style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                              ),
                              value: _isFacebookLive,
                              activeThumbColor: c.accentGold,
                              onChanged: (v) => setState(() => _isFacebookLive = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accentGold,
                          foregroundColor: c.backgroundPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.backgroundPrimary,
                                ),
                              )
                            : Text(
                                'Save',
                                style: AppTheme.lato(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

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
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.lato(fontSize: 12, color: c.textFaint),
            filled: true,
            fillColor: c.backgroundSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.accentGold.o(0.7), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
