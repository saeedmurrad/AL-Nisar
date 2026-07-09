import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/utils/external_link_launcher.dart';

void main() {
  test('normalizeFacebookPageUrl keeps www facebook page path', () {
    expect(
      normalizeFacebookPageUrl('https://www.facebook.com/SufiNisarAhmad'),
      'https://www.facebook.com/SufiNisarAhmad',
    );
    expect(
      normalizeFacebookPageUrl('https://m.facebook.com/SufiNisarAhmad'),
      'https://www.facebook.com/SufiNisarAhmad',
    );
    expect(
      normalizeFacebookPageUrl('https://facebook.com/SufiNisarAhmad/'),
      'https://www.facebook.com/SufiNisarAhmad/',
    );
  });

  test('normalizeFacebookPageUrl leaves live URLs unchanged', () {
    const live = 'https://www.facebook.com/SufiNisarAhmad/live';
    expect(normalizeFacebookPageUrl(live), live);
  });

  test('facebookAppUri encodes page URL for native app fallback', () {
    final uri = facebookAppUri('https://www.facebook.com/SufiNisarAhmad');
    expect(uri.scheme, 'fb');
    expect(uri.toString(), startsWith('fb://facewebmodal'));
    expect(
      uri.queryParameters['href'],
      'https://www.facebook.com/SufiNisarAhmad',
    );
  });

  test('youtubeAppUri builds vnd.youtube deep link', () {
    final uri = youtubeAppUri('https://www.youtube.com/@sufinisarahmad159');
    expect(uri.scheme, 'vnd.youtube');
    expect(uri.toString(), 'vnd.youtube://www.youtube.com/@sufinisarahmad159');
  });
}
