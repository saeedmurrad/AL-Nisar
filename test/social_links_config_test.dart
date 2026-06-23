import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/config/social_links.dart';
import 'package:spiritual_learning_app/models/social_links_config.dart';

void main() {
  test('defaults use confirmed Facebook and YouTube URLs', () {
    expect(
      SocialLinksConfig.defaults.facebookPageUrl,
      SocialLinksDefaults.facebookPageUrl,
    );
    expect(
      SocialLinksConfig.defaults.youtubeChannelUrl,
      SocialLinksDefaults.youtubeChannelUrl,
    );
  });

  test('fromMap parses Firestore fields', () {
    final config = SocialLinksConfig.fromMap({
      'facebookPageUrl': 'https://www.facebook.com/TestPage',
      'youtubeChannelUrl': 'https://www.youtube.com/@test',
      'facebookLiveUrl': 'https://www.facebook.com/live/123',
      'isFacebookLive': true,
    });
    expect(config.facebookPageUrl, 'https://www.facebook.com/TestPage');
    expect(config.youtubeChannelUrl, 'https://www.youtube.com/@test');
    expect(config.facebookLiveUrl, 'https://www.facebook.com/live/123');
    expect(config.isFacebookLive, isTrue);
    expect(config.showFacebookLiveBanner, isTrue);
  });

  test('fromMap falls back to defaults when empty', () {
    expect(SocialLinksConfig.fromMap(null), SocialLinksConfig.defaults);
    expect(SocialLinksConfig.fromMap({}), SocialLinksConfig.defaults);
  });

  test('showFacebookLiveBanner requires live URL', () {
    const config = SocialLinksConfig(
      facebookPageUrl: SocialLinksDefaults.facebookPageUrl,
      youtubeChannelUrl: SocialLinksDefaults.youtubeChannelUrl,
      isFacebookLive: true,
    );
    expect(config.showFacebookLiveBanner, isFalse);
  });
}
