import '../config/social_links.dart';

class SocialLinksConfig {
  const SocialLinksConfig({
    required this.facebookPageUrl,
    required this.youtubeChannelUrl,
    this.facebookLiveUrl = '',
    this.isFacebookLive = false,
  });

  final String facebookPageUrl;
  final String youtubeChannelUrl;
  final String facebookLiveUrl;
  final bool isFacebookLive;

  static const defaults = SocialLinksConfig(
    facebookPageUrl: SocialLinksDefaults.facebookPageUrl,
    youtubeChannelUrl: SocialLinksDefaults.youtubeChannelUrl,
  );

  factory SocialLinksConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    return SocialLinksConfig(
      facebookPageUrl:
          _str(data['facebookPageUrl']) ?? SocialLinksDefaults.facebookPageUrl,
      youtubeChannelUrl:
          _str(data['youtubeChannelUrl']) ??
          SocialLinksDefaults.youtubeChannelUrl,
      facebookLiveUrl: _str(data['facebookLiveUrl']) ?? '',
      isFacebookLive: data['isFacebookLive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facebookPageUrl': facebookPageUrl,
      'youtubeChannelUrl': youtubeChannelUrl,
      'facebookLiveUrl': facebookLiveUrl,
      'isFacebookLive': isFacebookLive,
    };
  }

  static String? _str(dynamic v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  bool get showFacebookLiveBanner =>
      isFacebookLive && facebookLiveUrl.trim().isNotEmpty;
}
