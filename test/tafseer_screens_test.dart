import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spiritual_learning_app/auth/auth_provider.dart';
import 'package:spiritual_learning_app/auth/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spiritual_learning_app/screens/tafseer_list_screen.dart';
import 'package:spiritual_learning_app/widgets/tafseer_search_result_card.dart';
import 'package:spiritual_learning_app/screens/tafseer_ruku_screen.dart';
import 'package:spiritual_learning_app/screens/tafseer_surah_screen.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';
import 'package:spiritual_learning_app/widgets/tafseer_print_button.dart';
import 'package:spiritual_learning_app/theme/app_theme_colors.dart';
import 'package:spiritual_learning_app/theme/tafseer_theme.dart';

/// The app's real palette isn't needed here — any AppThemeColors will do, since
/// the tafseer screens override it with their own reading palette.
const _colors = AppThemeColors(
  backgroundPrimary: Color(0xFFF5F8F5),
  backgroundSurface: Color(0xFFFFFFFF),
  backgroundElevated: Color(0xFFEFF3EF),
  backgroundInput: Color(0xFFFFFFFF),
  accentGold: Color(0xFF0E7A55),
  textPrimary: Color(0xFF11221A),
  textSecondary: Color(0xFF3A4A42),
  textMuted: Color(0xFF6B7A72),
  textFaint: Color(0xFF9AA79F),
  borderDefault: Color(0xFFD7E0DA),
  borderFaint: Color(0xFFE8EEEA),
);

/// Serves the repo's real asset files synchronously, so the screens' loads
/// resolve on microtasks and plain `pump()` is enough to see the result.
class _DiskBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.view(File(key).readAsBytesSync().buffer));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => parser(File(key).readAsStringSync());
}

final _service = TafseerBundledService(bundle: _DiskBundle());

class _FakeAuthService implements AuthService {
  @override
  Stream<User?> get authState => const Stream<User?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// AuthProvider with the role forced; the real one needs a live Firebase app.
class _FakeAuth extends AuthProvider {
  _FakeAuth({required this.superAdmin}) : super(service: _FakeAuthService());

  final bool superAdmin;

  @override
  bool get isSuperAdmin => superAdmin;

  @override
  bool get isAdminOrHigher => superAdmin;
}

Widget _app(
  Widget home, {
  Brightness brightness = Brightness.light,
  bool superAdmin = false,
}) {
  final router = GoRouter(
    initialLocation: '/x',
    routes: [GoRoute(path: '/x', builder: (_, _) => home)],
  );
  final base = brightness == Brightness.dark
      ? ThemeData.dark()
      : ThemeData.light();
  return ChangeNotifierProvider<AuthProvider>.value(
    value: _FakeAuth(superAdmin: superAdmin),
    child: MaterialApp.router(
      routerConfig: router,
      theme: base.copyWith(extensions: const [_colors]),
    ),
  );
}

/// Pumps a fixed number of frames rather than settling: google_fonts schedules
/// work that never quiets in tests.
Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Brightness brightness = Brightness.light,
  bool superAdmin = false,
}) async {
  await tester.pumpWidget(
    _app(home, brightness: brightness, superAdmin: superAdmin),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('index screen lists every bundled surah', (tester) async {
    tester.view.physicalSize = const Size(900, 20200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, TafseerListScreen(service: _service));

    expect(find.text('Ishari Commentary'), findsOneWidget);

    // One card per surah, each with its own Urdu name and number badge.
    for (final (name, badge) in const [
      ('سورۂ یوسف', '۱۲'),
      ('سورۂ رعد', '۱۳'),
      ('سورۂ ابراہیم', '۱۴'),
      ('سورۂ الحجر', '۱۵'),
      ('سورۂ النحل', '۱۶'),
      ('سورۂ بنی اسرائیل', '۱۷'),
      ('سورۂ الکہف', '۱۸'),
      ('سورۂ مریم', '۱۹'),
      ('سورۂ طٰہٰ', '۲۰'),
      ('سورۂ الانبیاء', '۲۱'),
      ('سورۂ الحج', '۲۲'),
      ('سورۂ المؤمنون', '۲۳'),
      ('سورۂ النور', '۲۴'),
      ('سورۂ الفرقان', '۲۵'),
      ('سورۂ الشعراء', '۲۶'),
      ('سورۂ النمل', '۲۷'),
      ('سورۂ القصص', '۲۸'),
      ('سورۂ العنکبوت', '۲۹'),
      ('سورۂ الروم', '۳۰'),
      ('سورۂ لقمان', '۳۱'),
      ('سورۂ السجدہ', '۳۲'),
      ('سورۂ الاحزاب', '۳۳'),
      ('سورۂ سبا', '۳۴'),
      ('سورۂ فاطر', '۳۵'),
      ('سورۂ یٰسٓ', '۳۶'),
      ('سورۂ الصّٰفّٰت', '۳۷'),
      ('سورۂ صٓ', '۳۸'),
      ('سورۂ الزمر', '۳۹'),
      ('سورۂ غافر (المؤمن)', '۴۰'),
      ('سورۂ حٰمٓ السجدہ (فصلت)', '۴۱'),
      ('سورۂ الشوریٰ', '۴۲'),
      ('سورۂ الزخرف', '۴۳'),
      ('سورۂ الدخان', '۴۴'),
      ('سورۂ الجاثیہ', '۴۵'),
      ('سورۂ الاحقاف', '۴۶'),
      ('سورۂ محمد', '۴۷'),
      ('سورۂ الفتح', '۴۸'),
      ('سورۂ الحجرات', '۴۹'),
      ('سورۂ قٓ', '۵۰'),
      ('سورۂ الذاریات', '۵۱'),
      ('سورۂ الطور', '۵۲'),
      ('سورۂ النجم', '۵۳'),
      ('سورۂ القمر', '۵۴'),
      ('سورۂ الرحمٰن', '۵۵'),
      ('سورۂ الواقعہ', '۵۶'),
      ('سورۂ الحدید', '۵۷'),
      ('سورۂ المجادلہ', '۵۸'),
      ('سورۂ الحشر', '۵۹'),
      ('سورۂ الممتحنہ', '۶۰'),
      ('سورۂ الصف', '۶۱'),
      ('سورۂ الجمعہ', '۶۲'),
      ('سورۂ المنافقون', '۶۳'),
      ('سورۂ التغابن', '۶۴'),
      ('سورۂ الطلاق', '۶۵'),
      ('سورۂ التحریم', '۶۶'),
      ('سورۂ الملک', '۶۷'),
      ('سورۂ القلم', '۶۸'),
      ('سورۂ الحاقہ', '۶۹'),
      ('سورۂ المعارج', '۷۰'),
      ('سورۂ نوح', '۷۱'),
      ('سورۂ الجن', '۷۲'),
      ('سورۂ المزمل', '۷۳'),
      ('سورۂ المدثر', '۷۴'),
      ('سورۂ القیامہ', '۷۵'),
      ('سورۂ الدہر', '۷۶'),
      ('سورۂ المرسلات', '۷۷'),
      ('سورۂ النبا', '۷۸'),
      ('سورۂ النازعات', '۷۹'),
      ('سورۂ عبس', '۸۰'),
      ('سورۂ التکویر', '۸۱'),
      ('سورۂ الانفطار', '۸۲'),
      ('سورۂ المطففین', '۸۳'),
      ('سورۂ الانشقاق', '۸۴'),
      ('سورۂ البروج', '۸۵'),
      ('سورۂ الطارق', '۸۶'),
      ('سورۂ الاعلیٰ', '۸۷'),
      ('سورۂ الغاشیہ', '۸۸'),
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
      expect(find.text(badge), findsOneWidget, reason: badge);
    }

    expect(find.text('16 rukus · Urdu'), findsOneWidget);
    // Yusuf, Bani Israel and Al-Kahf all have twelve.
    expect(find.text('12 rukus · Urdu'), findsNWidgets(3));
    expect(find.text('11 rukus · Urdu'), findsOneWidget);
    expect(find.text('10 rukus · Urdu'), findsOneWidget);
    // An-Nur, Al-Qasas, Al-Ahzab and Ghafir all have nine.
    expect(find.text('9 rukus · Urdu'), findsNWidgets(4));
    // Ta-Ha and Az-Zumar.
    expect(find.text('8 rukus · Urdu'), findsNWidgets(2));
    // Ibrahim, Al-Anbiya, An-Naml, Al-Ankabut and Az-Zukhruf.
    expect(find.text('7 rukus · Urdu'), findsNWidgets(5));
    // Ar-Ra'd, Al-Hijr, Maryam, Al-Mu'minun, Al-Furqan, Ar-Rum, Saba and
    // Fussilat.
    expect(find.text('6 rukus · Urdu'), findsNWidgets(8));
    // Fatir, Ya-Sin, As-Saffat, Sad and Ash-Shura.
    expect(find.text('5 rukus · Urdu'), findsNWidgets(5));
    // Luqman, Al-Jathiya, Al-Ahqaf, Muhammad, Al-Fath and Al-Hadid.
    expect(find.text('4 rukus · Urdu'), findsNWidgets(6));
    // As-Sajdah, Ad-Dukhan, Qaf, Adh-Dhariyat, An-Najm, Al-Qamar,
    // Ar-Rahman, Al-Waqi'ah, Al-Mujadilah and Al-Hashr.
    expect(find.text('3 rukus · Urdu'), findsNWidgets(10));
    // Al-Hujurat, At-Tur, the nineteen short surahs from Al-Mumtahanah
    // through An-Naba, and An-Nazi'at.
    expect(find.text('2 rukus · Urdu'), findsNWidgets(22));
    // 'Abasa through Al-Ghashiyah are a single ruku each, so the noun is
    // singular — "1 rukus" would be wrong.
    expect(find.text('1 ruku · Urdu'), findsNWidgets(9));
    expect(find.text('1 rukus · Urdu'), findsNothing);
  });

  testWidgets('each surah screen renders its own contents', (tester) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final (id, first, last, lastNum, pastEnd) in const [
      ('raad', 'ایک پانی، مختلف پھل', 'محو و اثبات اور اُمّ الکتاب', '۶', '۷'),
      ('ibrahim', 'ظلمات سے نور تک', 'تبدیلِ ارض اور بلاغ', '۷', '۸'),
      ('hijr', 'ذکرِ محفوظ اور مسحور نگاہ', 'یقین کی آمد تک', '۶', '۷'),
      ('nahl', 'امر کی آمد اور سیدھی راہ', 'ایک فرد، پوری امت', '۱۶', '۱۷'),
      (
        'bani-israel',
        'شبِ اسرا اور مقامِ عبدیت',
        'سبحان سے تکبیر تک',
        '۱۲',
        '۱۳',
      ),
      ('kahf', 'عبد کی کتاب اور غارِ دل', 'کلماتِ رب اور لقاء', '۱۲', '۱۳'),
      (
        'maryam',
        'ذکرِ رحمت اور بشارتِ یحییٰ',
        'عبدیتِ کُل، وُدِّ رحمٰن',
        '۶',
        '۷',
      ),
      ('taha', 'وادیِ طویٰ کی آگ', 'تسبیح، صبر اور رضا', '۸', '۹'),
      ('anbiya', 'تمہارے ذکر والی کتاب', 'تمام جہانوں کے لیے رحمت', '۷', '۸'),
      (
        'hajj',
        'زلزلۂ ساعت اور خلقِ جدید',
        'مکھی کی مثال اور حقِ جہاد',
        '۱۰',
        '۱۱',
      ),
      (
        'muminun',
        'فلاح کی منزلیں اور خلقِ آخر',
        'برزخ سے خیر الراحمین تک',
        '۶',
        '۷',
      ),
      ('nur', 'نور کی چار دیواری', 'ادبِ رسالت اور علمِ محیط', '۹', '۱۰'),
      ('furqan', 'بندے پر اترا فرقان', 'رحمٰن کے بندوں کا سراپا', '۶', '۷'),
      (
        'shuara',
        'نشانی اور اختیار کی عزت',
        'قلب پر نزول اور اہلِ ذکر',
        '۱۱',
        '۱۲',
      ),
      ('naml', 'آگ کی صورت میں تجلی', 'بادل کی طرح گزرتے پہاڑ', '۷', '۸'),
      ('qasas', 'دریا کی گود میں امان', 'ہر شے فانی، وجہ باقی', '۹', '۱۰'),
      ('ankabut', 'آزمائش کی بھٹی', 'ہم میں کوشش، ہماری راہیں', '۷', '۸'),
      ('rum', 'ظاہرِ دنیا اور غفلتِ آخرت', 'ضعف سے ضعف تک', '۶', '۷'),
      ('luqman', 'کتابِ حکیم اور اہلِ احسان', 'غیب کی پانچ کنجیاں', '۴', '۵'),
      ('sajdah', 'مٹی، تدبیر اور نفخِ روح', 'صبر، یقین اور فتح', '۳', '۴'),
      ('ahzab', 'ایک دل، ایک محبوب', 'امانت کا بارِ عظیم', '۹', '۱۰'),
      ('saba', 'دونوں جہانوں کی حمد', 'مثنیٰ و فرادیٰ کی نصیحت', '۶', '۷'),
      ('fatir', 'رحمت کی فتح', 'تھاما ہوا وجود', '۵', '۶'),
      ('yasin', 'قرآنِ حکیم اور امامِ مبین', 'عدم میں کُن کی سماعت', '۵', '۶'),
      ('saffat', 'صفیں اور معبودِ واحد', 'ہر ایک کا مقامِ معلوم', '۵', '۶'),
      ('sad', 'یاد دہانی والا قرآن', 'دونوں ہاتھوں کی تخلیق', '۵', '۶'),
      ('zumar', 'خالص دین اللہ کا ہے', 'کھلے دروازے اور آخری حمد', '۸', '۹'),
      ('ghafir', 'رحمت اور علم کی وسعت', 'اپنے علم کا پردہ', '۹', '۱۰'),
      (
        'fussilat',
        'رحمٰن کی کھولی ہوئی کتاب',
        'آفاق و انفس کی نشانیاں',
        '۶',
        '۷',
      ),
      ('shura', 'ایک وحی، ایک ولی', 'کلامِ الٰہی کے تین راستے', '۵', '۶'),
      ('zukhruf', 'امّ الکتاب اور سواری', 'اے میرے بندو سے سلام تک', '۷', '۸'),
      (
        'dukhan',
        'بابرکت رات اور خاموش آسمان',
        'زقوم اور امن کا مقام',
        '۳',
        '۴',
      ),
      ('jathiya', 'ایمان، یقین اور عقل', 'گھٹنوں کے بل امتیں', '۴', '۵'),
      ('ahqaf', 'عبدیتِ کاملہ کا اعلان', 'خاموشی، سماع کا دروازہ', '۴', '۵'),
      ('muhammad', 'جن کا حال سنوار دیا گیا', 'اللہ غنی، تم فقیر', '۴', '۵'),
      ('fath', 'فتحِ مبین اور سکینہ', 'سچا خواب اور اصحاب کی تصویر', '۴', '۵'),
      (
        'hujurat',
        'ادبِ حضور اور ایمانی اخوت',
        'عزتِ انسان اور ایمان کی حقیقت',
        '۲',
        '۳',
      ),
      ('qaf', 'ہر سانس ایک نئی پیدائش', 'مزید کا راز اور صاحبِ قلب', '۳', '۴'),
      ('dhariyat', 'آفاق و انفس کی نشانیاں', 'اللہ کی طرف فرار', '۳', '۴'),
      ('tur', 'طور کی قسم اور البر الرحیم', 'ہماری آنکھوں کے سامنے', '۲', '۳'),
      ('najm', 'معراج اور ادبِ نگاہ', 'سعی، منتہیٰ اور سجدہ', '۳', '۴'),
      ('qamar', 'شقِ قمر اور یاد دہانی', 'قدر، کن اور مقعدِ صدق', '۳', '۴'),
      ('rahman', 'رحمٰن نے قرآن سکھایا', 'دو باغ اور بابرکت نام', '۳', '۴'),
      (
        'waqiah',
        'واقعہ اور تین جماعتیں',
        'کتابِ مکنون اور حق الیقین',
        '۳',
        '۴',
      ),
      ('hadid', 'اول و آخر، ظاہر و باطن', 'رہبانیت اور چلنے کا نور', '۴', '۵'),
      ('mujadilah', 'فریاد جو سنی گئی', 'فراموشیِ ذکر اور حزب اللہ', '۳', '۴'),
      (
        'hashr',
        'ایثار اور بے کینہ دل',
        'نسیانِ نفس اور اسماءِ حسنیٰ',
        '۳',
        '۴',
      ),
      (
        'mumtahanah',
        'اسوۂ ابراہیم اور دعائے توکل',
        'نیکی، انصاف اور بیعتِ مومنات',
        '۲',
        '۳',
      ),
      (
        'saff',
        'صدقِ قول اور بشارتِ احمد',
        'تجارتِ نجات اور انصارِ الٰہی',
        '۲',
        '۳',
      ),
      ('jumuah', 'تلاوت، تزکیہ اور حکمت', 'ندائے جمعہ اور ذکرِ کثیر', '۲', '۳'),
      ('munafiqun', 'سچا کلمہ، جھوٹی گواہی', 'ذکر، انفاق اور مہلت', '۲', '۳'),
      ('taghabun', 'ایک خلق، دو رخ', 'ایمان اور ہدایتِ قلب', '۲', '۳'),
      ('talaq', 'تقویٰ اور کشادگی کی راہ', 'طبقات میں اترتا امر', '۲', '۳'),
      (
        'tahrim',
        'خانۂ نبوت اور دعوتِ توبہ',
        'توبۂ نصوح اور چار مثالیں',
        '۲',
        '۳',
      ),
      (
        'mulk',
        'بادشاہی اسی کے ہاتھ میں',
        'رحمٰن کے تھامے ہوئے پرندے',
        '۲',
        '۳',
      ),
      (
        'qalam',
        'قلم، خلقِ عظیم اور باغ والے',
        'سجدے کی پکار اور صاحبِ حوت',
        '۲',
        '۳',
      ),
      (
        'haqqah',
        'الحاقہ، گوشِ واعیہ اور دو نامے',
        'دیدہ و نادیدہ اور حق الیقین',
        '۲',
        '۳',
      ),
      (
        'maarij',
        'زینوں کا رب اور دائم نمازی',
        'مشرقوں اور مغربوں کا رب',
        '۲',
        '۳',
      ),
      ('nuh', 'رات دن کی پکار اور استغفار', 'پانچ نام اور جامع دعا', '۲', '۳'),
      ('jinn', 'جنوں کا سماع اور عبدیت', 'غیب کا امین رسول', '۲', '۳'),
      ('muzzammil', 'قیامِ شب، ترتیل اور تبتل', 'تخفیف کی رحمت', '۲', '۳'),
      (
        'muddaththir',
        'قیام، تکبیر اور فتنۂ عدد',
        'گروی جانیں اور دو مشیتیں',
        '۲',
        '۳',
      ),
      ('qiyamah', 'نفسِ لوامہ اور دیدارِ رب', 'انسان بے مہار نہیں', '۲', '۳'),
      ('dahr', 'نامذکور سے شرابِ طہور تک', 'دو مشیتیں، ایک راستہ', '۲', '۳'),
      (
        'mursalat',
        'قسمیں، پیمانہ اور یومِ فصل',
        'سایے، چشمے اور رکوع کی پکار',
        '۲',
        '۳',
      ),
      ('naba', 'بڑی خبر اور سراب پہاڑ', 'رب کی طرف ٹھکانا', '۲', '۳'),
      ('naziat', 'کیا تو پاک ہونا چاہتا ہے؟', 'دو راستے، دو ٹھکانے', '۲', '۳'),
      ('abasa', 'طالب کی قدر و منزلت', 'طالب کی قدر و منزلت', '۱', '۲'),
      (
        'takwir',
        'جان کی حاضری، صبح کی سانس',
        'جان کی حاضری، صبح کی سانس',
        '۱',
        '۲',
      ),
      (
        'infitar',
        'ربِّ کریم کا پیار بھرا عتاب',
        'ربِّ کریم کا پیار بھرا عتاب',
        '۱',
        '۲',
      ),
      (
        'mutaffifin',
        'ناپ تول، زنگ اور تسنیم',
        'ناپ تول، زنگ اور تسنیم',
        '۱',
        '۲',
      ),
      ('inshiqaq', 'رب کی طرف کدح', 'رب کی طرف کدح', '۱', '۲'),
      ('buruj', 'خندق کی آگ اور ودود رب', 'خندق کی آگ اور ودود رب', '۱', '۲'),
      (
        'tariq',
        'رات کا دستک دینے والا تارا',
        'رات کا دستک دینے والا تارا',
        '۱',
        '۲',
      ),
      ('ala', 'ربِّ اعلیٰ کی تسبیح', 'ربِّ اعلیٰ کی تسبیح', '۱', '۲'),
      (
        'ghashiyah',
        'یاد دلانے والا، داروغہ نہیں',
        'یاد دلانے والا، داروغہ نہیں',
        '۱',
        '۲',
      ),
    ]) {
      await _pump(tester, TafseerSurahScreen(surahId: id, service: _service));

      expect(find.text('فہرستِ رکوع'), findsOneWidget, reason: id);
      expect(find.text(first), findsOneWidget, reason: '$id first');
      expect(find.text(last), findsOneWidget, reason: '$id last');
      // The contents stop at this surah's own ruku count.
      expect(find.text(lastNum), findsOneWidget, reason: '$id last number');
      expect(find.text(pastEnd), findsNothing, reason: '$id past end');
    }
  });

  testWidgets('Al-Hijr reader renders the Iblis ruku with its glossary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'hijr', rukuNumber: 3, service: _service),
    );

    expect(find.text('تیسرا رکوع · آیات ۲۶ تا ۴۴'), findsOneWidget);
    expect(find.text('نفخِ روح اور سجدۂ ملائک'), findsOneWidget);
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);
    expect(find.text('صلصال'), findsOneWidget); // a glossary term

    // Mid-surah: both directions available.
    for (final label in const ['← پچھلا رکوع', 'اگلا رکوع →']) {
      final b = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(b.onPressed, isNotNull, reason: label);
    }
  });

  testWidgets('Ar-Rad reader renders body and glossary, and ends at ruku 6', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'raad', rukuNumber: 6, service: _service),
    );

    expect(find.text('چھٹا رکوع · آیات ۳۸ تا ۴۳'), findsOneWidget);
    expect(find.text('محو و اثبات اور اُمّ الکتاب'), findsOneWidget);
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);

    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final prev = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('← پچھلا رکوع'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(next.onPressed, isNull); // last ruku of this surah
    expect(prev.onPressed, isNotNull);
  });

  testWidgets('reader adopts the dark paper palette in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
      brightness: Brightness.dark,
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, kTafseerDarkColors.backgroundPrimary);

    final spans = <TextSpan>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) spans.add(span);
        return true;
      });
    }
    final ayah = spans.firstWhere(
      (s) => (s.text ?? '').contains('نَحْنُ نَقُصُّ'),
    );
    expect(ayah.style?.color, kTafseerDarkColors.accentGold);
  });

  testWidgets('surah screen renders masthead, key and all 12 ruku rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerSurahScreen(surahId: 'yusuf', service: _service),
    );

    expect(find.text('تفسیرِ ابنِ عربی'), findsOneWidget);
    expect(find.textContaining('بِسْمِ'), findsWidgets);
    expect(find.text('اردو · اشاری تفسیر · رکوع بہ رکوع'), findsOneWidget);
    expect(find.text('فہرستِ رکوع'), findsOneWidget);

    // Every ruku title is listed in the contents.
    for (final title in const [
      'خوابِ ازل',
      'کنویں کی خلوت',
      'برہانِ رب',
      'آیت، بصیرت اور عبور',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    // Urdu-Indic numerals in the index, not Western digits.
    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۱۲'), findsOneWidget);
  });

  testWidgets('surah screen shows a branded state for an unknown surah', (
    tester,
  ) async {
    await _pump(
      tester,
      TafseerSurahScreen(surahId: 'baqarah', service: _service),
    );
    expect(find.text('Tafseer not found'), findsOneWidget);
  });

  testWidgets('ruku screen renders marker, ayah block, body and glossary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
    );

    expect(find.text('پہلا رکوع · آیات ۱ تا ۶'), findsOneWidget);
    expect(find.text('ع'), findsOneWidget);
    expect(find.text('خوابِ ازل'), findsOneWidget);
    expect(
      find.text('الٓرٰ ۚ تِلْكَ اٰيٰتُ الْكِتٰبِ الْمُبِيْنِ'),
      findsOneWidget,
    );

    // Body prose came through the HTML renderer.
    expect(find.textContaining('حروفِ مقطعات'), findsWidgets);

    // Glossary panel.
    expect(find.text('مشکل الفاظ اور اصطلاحاتِ فقر'), findsOneWidget);
    expect(find.text('نفَسِ رحمانی'), findsOneWidget);

    // Paging controls: no previous ruku before #1, next is available.
    final prev = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('← پچھلا رکوع'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(prev.onPressed, isNull);
    expect(next.onPressed, isNotNull);
  });

  testWidgets('last ruku disables Next', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 12, service: _service),
    );

    final next = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('اگلا رکوع →'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('a single-ruku surah disables both Prev and Next', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Al-Ghashiyah is one ruku, so it is both the first and the last.
    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'ghashiyah', rukuNumber: 1, service: _service),
    );

    expect(find.text('یاد دلانے والا، داروغہ نہیں'), findsOneWidget);
    for (final label in const ['← پچھلا رکوع', 'اگلا رکوع →']) {
      final b = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(b.onPressed, isNull, reason: label);
    }
  });

  testWidgets('inline .ayah spans are restyled saffron, body prose is not', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
    );

    // Collect every styled leaf span rendered by flutter_html.
    final spans = <TextSpan>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) spans.add(span);
        return true;
      });
    }

    TextSpan spanContaining(String needle) => spans.firstWhere(
      (s) => (s.text ?? '').contains(needle),
      orElse: () => throw StateError('no span containing "\$needle"'),
    );

    // An inline Quranic fragment carried by <span class="ayah">.
    final ayah = spanContaining('نَحْنُ نَقُصُّ');
    expect(ayah.style?.color, kTafseerLightColors.accentGold);
    expect(ayah.style?.fontWeight, FontWeight.w700);

    // Surrounding Urdu prose keeps the ink colour, not the ayah colour.
    final prose = spanContaining('سورت کا آغاز');
    expect(prose.style?.color, kTafseerLightColors.textPrimary);
    expect(prose.style?.color, isNot(kTafseerLightColors.accentGold));

    // The two are rendered in different families.
    expect(ayah.style?.fontFamily, isNot(prose.style?.fontFamily));
  });

  testWidgets('searching shows results and hides the surah list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, TafseerListScreen(service: _service));
    expect(find.text('سورۂ یوسف'), findsOneWidget);

    // Typed without diacritics — the fold is what makes this match.
    await tester.enterText(find.byType(TextField), 'نحن نقص');
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('match'), findsWidgets);
    expect(find.byType(TafseerSearchResultCard), findsWidgets);
    // The surah picker is replaced while a query is active.
    expect(find.text('Ishari Commentary'), findsNothing);
  });

  testWidgets('a query with no matches shows the empty state', (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, TafseerListScreen(service: _service));
    await tester.enterText(find.byType(TextField), 'zzzqqqxx');
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('No matches'), findsOneWidget);
    expect(find.byType(TafseerSearchResultCard), findsNothing);
  });

  testWidgets('.ayah still matches spans that carry extra attributes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Bani Israel writes <span class="ayah" data-a="N">; the earlier surahs
    // write a bare class. The class selector must match either way.
    await _pump(
      tester,
      TafseerRukuScreen(
        surahId: 'bani-israel',
        rukuNumber: 1,
        service: _service,
      ),
    );

    final spans = <TextSpan>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) spans.add(span);
        return true;
      });
    }
    final ayah = spans.firstWhere(
      (s) => (s.text ?? '').contains('اَسْرٰى بِعَبْدِهٖ'),
      orElse: () => throw StateError('no ayah span found'),
    );
    expect(ayah.style?.color, kTafseerLightColors.accentGold);
    expect(ayah.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('copy action is hidden from a regular member', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 1, service: _service),
    );
    expect(find.byIcon(Icons.copy_all_outlined), findsNothing);
  });

  testWidgets('super admin can copy the ruku text to the clipboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pump(
      tester,
      TafseerRukuScreen(
        surahId: 'bani-israel',
        rukuNumber: 5,
        service: _service,
      ),
      superAdmin: true,
    );

    expect(find.byIcon(Icons.copy_all_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pump();
    await tester.pump();

    expect(copied, isNotNull);
    expect(copied, contains('سورۂ بنی اسرائیل'));
    expect(copied, contains('پانچواں رکوع'));
    // Ruku 5's ayah block is the one wrapped in <span data-a="44"> upstream.
    expect(copied, contains('وَاِنْ مِّنْ شَيْءٍ اِلَّا يُسَبِّحُ'));
    expect(copied, isNot(contains('<')));
    expect(find.textContaining('copied to clipboard'), findsOneWidget);
  });

  testWidgets('out-of-range ruku shows a branded state', (tester) async {
    await _pump(
      tester,
      TafseerRukuScreen(surahId: 'yusuf', rukuNumber: 99, service: _service),
    );
    expect(find.text('Ruku not found'), findsOneWidget);
  });

  testWidgets('every member gets the print button, not just super admins', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerSurahScreen(
        surahId: 'dukhan',
        service: _service,
        canPrint: true,
        printDocument: (_) async {},
      ),
      // A plain member: the copy action is super-admin only, printing is not.
      superAdmin: false,
    );

    expect(find.byType(TafseerPrintButton), findsOneWidget);
    expect(find.byIcon(Icons.print_outlined), findsOneWidget);
  });

  testWidgets('the print button is hidden where printing is unsupported', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      TafseerSurahScreen(surahId: 'dukhan', service: _service, canPrint: false),
    );

    expect(find.byType(TafseerPrintButton), findsNothing);
  });

  testWidgets('printing hands over the whole surah, every ruku included', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? printed;
    await _pump(
      tester,
      TafseerSurahScreen(
        surahId: 'dukhan',
        service: _service,
        canPrint: true,
        printDocument: (html) async => printed = html,
      ),
    );

    await tester.tap(find.byIcon(Icons.print_outlined));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(printed, isNotNull);
    // All three rukus, each with its title and its body prose.
    expect('<section class="ruku">'.allMatches(printed!).length, 3);
    expect(printed, contains('بابرکت رات اور خاموش آسمان'));
    expect(printed, contains('زقوم اور امن کا مقام'));
    expect(printed, contains('class="ayah"'));
    // Black ink: the reading theme's saffron must not reach the page.
    expect(printed!.toUpperCase(), isNot(contains('#B07A12')));
  });
}
