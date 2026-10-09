import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/services/tafseer_bundled_service.dart';

/// An AssetBundle that has nothing in it, for the missing-content paths.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('missing: $key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = TafseerBundledService();

  // Al-Muzzammil's second ruku is the bundle's only single-ayah ruku: its
  // range arrives already labelled, so the eyebrow must not prepend the
  // plural and read "ayahs ayah 20".
  test('a single-ayah ruku keeps its own label in the eyebrow', () async {
    final surah = await service.loadSurah('muzzammil');
    final rukus = surah!.rukus;

    expect(rukus.first.ayahRangeUrdu, '۱ تا ۱۹');
    expect(rukus.first.eyebrow, 'پہلا رکوع · آیات ۱ تا ۱۹');

    expect(rukus.last.ayahRangeUrdu, 'آیت ۲۰');
    expect(rukus.last.eyebrow, 'دوسرا رکوع · آیت ۲۰');
    expect(rukus.last.eyebrow, isNot(contains('آیات آیت')));
  });

  // The bundle now runs unbroken from Surah Yusuf to the end of the Quran.
  // A missing or duplicated surah would otherwise only show as a shifted
  // count somewhere far away in the fixtures.
  test('index covers surahs 12 through 114 with no gaps', () async {
    final index = await service.loadIndex();
    final numbers = index.map((s) => s.surahNumber).toList();

    expect(numbers.first, 12);
    expect(numbers.last, 114);
    expect(numbers, List<int>.generate(114 - 12 + 1, (i) => 12 + i));
    expect(numbers.toSet(), hasLength(numbers.length));
    expect(index.map((s) => s.id).toSet(), hasLength(index.length));
  });

  test('index lists the bundled surahs in surah order', () async {
    final index = await service.loadIndex();
    expect(index.map((s) => s.id).toList(), [
      'yusuf',
      'raad',
      'ibrahim',
      'hijr',
      'nahl',
      'bani-israel',
      'kahf',
      'maryam',
      'taha',
      'anbiya',
      'hajj',
      'muminun',
      'nur',
      'furqan',
      'shuara',
      'naml',
      'qasas',
      'ankabut',
      'rum',
      'luqman',
      'sajdah',
      'ahzab',
      'saba',
      'fatir',
      'yasin',
      'saffat',
      'sad',
      'zumar',
      'ghafir',
      'fussilat',
      'shura',
      'zukhruf',
      'dukhan',
      'jathiya',
      'ahqaf',
      'muhammad',
      'fath',
      'hujurat',
      'qaf',
      'dhariyat',
      'tur',
      'najm',
      'qamar',
      'rahman',
      'waqiah',
      'hadid',
      'mujadilah',
      'hashr',
      'mumtahanah',
      'saff',
      'jumuah',
      'munafiqun',
      'taghabun',
      'talaq',
      'tahrim',
      'mulk',
      'qalam',
      'haqqah',
      'maarij',
      'nuh',
      'jinn',
      'muzzammil',
      'muddaththir',
      'qiyamah',
      'dahr',
      'mursalat',
      'naba',
      'naziat',
      'abasa',
      'takwir',
      'infitar',
      'mutaffifin',
      'inshiqaq',
      'buruj',
      'tariq',
      'ala',
      'ghashiyah',
      'fajr',
      'balad',
      'shams',
      'layl',
      'duha',
      'inshirah',
      'tin',
      'alaq',
      'qadr',
      'bayyinah',
      'zalzalah',
      'adiyat',
      'qariah',
      'takathur',
      'asr',
      'humazah',
      'fil',
      'quraish',
      'maun',
      'kawthar',
      'kafirun',
      'nasr',
      'lahab',
      'ikhlas',
      'falaq',
      'nas',
    ]);
    expect(index.map((s) => s.surahNumber).toList(), [
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
      77,
      78,
      79,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      89,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      98,
      99,
      100,
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110,
      111,
      112,
      113,
      114,
    ]);

    final yusuf = index.firstWhere((s) => s.id == 'yusuf');
    expect(yusuf.surahNumber, 12);
    expect(yusuf.rukuCount, 12);
    expect(yusuf.isAvailable, isTrue);
    expect(yusuf.nameUrdu, contains('یوسف'));

    final raad = index.firstWhere((s) => s.id == 'raad');
    expect(raad.surahNumber, 13);
    expect(raad.rukuCount, 6);
    expect(raad.isAvailable, isTrue);
    expect(raad.nameUrdu, contains('رعد'));
  });

  // Table-driven so adding a surah means adding one row, and a malformed
  // source page fails here rather than shipping empty rukus.
  const bundled =
      <
        String,
        ({int number, String name, int rukus, String first, String last})
      >{
        'raad': (
          number: 13,
          name: 'سورۂ رعد',
          rukus: 6,
          first: 'ایک پانی، مختلف پھل',
          last: 'محو و اثبات اور اُمّ الکتاب',
        ),
        'ibrahim': (
          number: 14,
          name: 'سورۂ ابراہیم',
          rukus: 7,
          first: 'ظلمات سے نور تک',
          last: 'تبدیلِ ارض اور بلاغ',
        ),
        'hijr': (
          number: 15,
          name: 'سورۂ الحجر',
          rukus: 6,
          first: 'ذکرِ محفوظ اور مسحور نگاہ',
          last: 'یقین کی آمد تک',
        ),
        'nahl': (
          number: 16,
          name: 'سورۂ النحل',
          rukus: 16,
          first: 'امر کی آمد اور سیدھی راہ',
          last: 'ایک فرد، پوری امت',
        ),
        'bani-israel': (
          number: 17,
          name: 'سورۂ بنی اسرائیل',
          rukus: 12,
          first: 'شبِ اسرا اور مقامِ عبدیت',
          last: 'سبحان سے تکبیر تک',
        ),
        'kahf': (
          number: 18,
          name: 'سورۂ الکہف',
          rukus: 12,
          first: 'عبد کی کتاب اور غارِ دل',
          last: 'کلماتِ رب اور لقاء',
        ),
        'maryam': (
          number: 19,
          name: 'سورۂ مریم',
          rukus: 6,
          first: 'ذکرِ رحمت اور بشارتِ یحییٰ',
          last: 'عبدیتِ کُل، وُدِّ رحمٰن',
        ),
        'taha': (
          number: 20,
          name: 'سورۂ طٰہٰ',
          rukus: 8,
          first: 'وادیِ طویٰ کی آگ',
          last: 'تسبیح، صبر اور رضا',
        ),
        'anbiya': (
          number: 21,
          name: 'سورۂ الانبیاء',
          rukus: 7,
          first: 'تمہارے ذکر والی کتاب',
          last: 'تمام جہانوں کے لیے رحمت',
        ),
        'hajj': (
          number: 22,
          name: 'سورۂ الحج',
          rukus: 10,
          first: 'زلزلۂ ساعت اور خلقِ جدید',
          last: 'مکھی کی مثال اور حقِ جہاد',
        ),
        'muminun': (
          number: 23,
          name: 'سورۂ المؤمنون',
          rukus: 6,
          first: 'فلاح کی منزلیں اور خلقِ آخر',
          last: 'برزخ سے خیر الراحمین تک',
        ),
        'nur': (
          number: 24,
          name: 'سورۂ النور',
          rukus: 9,
          first: 'نور کی چار دیواری',
          last: 'ادبِ رسالت اور علمِ محیط',
        ),
        'furqan': (
          number: 25,
          name: 'سورۂ الفرقان',
          rukus: 6,
          first: 'بندے پر اترا فرقان',
          last: 'رحمٰن کے بندوں کا سراپا',
        ),
        'shuara': (
          number: 26,
          name: 'سورۂ الشعراء',
          rukus: 11,
          first: 'نشانی اور اختیار کی عزت',
          last: 'قلب پر نزول اور اہلِ ذکر',
        ),
        'naml': (
          number: 27,
          name: 'سورۂ النمل',
          rukus: 7,
          first: 'آگ کی صورت میں تجلی',
          last: 'بادل کی طرح گزرتے پہاڑ',
        ),
        'qasas': (
          number: 28,
          name: 'سورۂ القصص',
          rukus: 9,
          first: 'دریا کی گود میں امان',
          last: 'ہر شے فانی، وجہ باقی',
        ),
        'ankabut': (
          number: 29,
          name: 'سورۂ العنکبوت',
          rukus: 7,
          first: 'آزمائش کی بھٹی',
          last: 'ہم میں کوشش، ہماری راہیں',
        ),
        'rum': (
          number: 30,
          name: 'سورۂ الروم',
          rukus: 6,
          first: 'ظاہرِ دنیا اور غفلتِ آخرت',
          last: 'ضعف سے ضعف تک',
        ),
        'luqman': (
          number: 31,
          name: 'سورۂ لقمان',
          rukus: 4,
          first: 'کتابِ حکیم اور اہلِ احسان',
          last: 'غیب کی پانچ کنجیاں',
        ),
        'sajdah': (
          number: 32,
          name: 'سورۂ السجدہ',
          rukus: 3,
          first: 'مٹی، تدبیر اور نفخِ روح',
          last: 'صبر، یقین اور فتح',
        ),
        'ahzab': (
          number: 33,
          name: 'سورۂ الاحزاب',
          rukus: 9,
          first: 'ایک دل، ایک محبوب',
          last: 'امانت کا بارِ عظیم',
        ),
        'saba': (
          number: 34,
          name: 'سورۂ سبا',
          rukus: 6,
          first: 'دونوں جہانوں کی حمد',
          last: 'مثنیٰ و فرادیٰ کی نصیحت',
        ),
        'fatir': (
          number: 35,
          name: 'سورۂ فاطر',
          rukus: 5,
          first: 'رحمت کی فتح',
          last: 'تھاما ہوا وجود',
        ),
        'yasin': (
          number: 36,
          name: 'سورۂ یٰسٓ',
          rukus: 5,
          first: 'قرآنِ حکیم اور امامِ مبین',
          last: 'عدم میں کُن کی سماعت',
        ),
        'saffat': (
          number: 37,
          name: 'سورۂ الصّٰفّٰت',
          rukus: 5,
          first: 'صفیں اور معبودِ واحد',
          last: 'ہر ایک کا مقامِ معلوم',
        ),
        'sad': (
          number: 38,
          name: 'سورۂ صٓ',
          rukus: 5,
          first: 'یاد دہانی والا قرآن',
          last: 'دونوں ہاتھوں کی تخلیق',
        ),
        'zumar': (
          number: 39,
          name: 'سورۂ الزمر',
          rukus: 8,
          first: 'خالص دین اللہ کا ہے',
          last: 'کھلے دروازے اور آخری حمد',
        ),
        'ghafir': (
          number: 40,
          name: 'سورۂ غافر (المؤمن)',
          rukus: 9,
          first: 'رحمت اور علم کی وسعت',
          last: 'اپنے علم کا پردہ',
        ),
        'fussilat': (
          number: 41,
          name: 'سورۂ حٰمٓ السجدہ (فصلت)',
          rukus: 6,
          first: 'رحمٰن کی کھولی ہوئی کتاب',
          last: 'آفاق و انفس کی نشانیاں',
        ),
        'shura': (
          number: 42,
          name: 'سورۂ الشوریٰ',
          rukus: 5,
          first: 'ایک وحی، ایک ولی',
          last: 'کلامِ الٰہی کے تین راستے',
        ),
        'zukhruf': (
          number: 43,
          name: 'سورۂ الزخرف',
          rukus: 7,
          first: 'امّ الکتاب اور سواری',
          last: 'اے میرے بندو سے سلام تک',
        ),
        'dukhan': (
          number: 44,
          name: 'سورۂ الدخان',
          rukus: 3,
          first: 'بابرکت رات اور خاموش آسمان',
          last: 'زقوم اور امن کا مقام',
        ),
        'jathiya': (
          number: 45,
          name: 'سورۂ الجاثیہ',
          rukus: 4,
          first: 'ایمان، یقین اور عقل',
          last: 'گھٹنوں کے بل امتیں',
        ),
        'ahqaf': (
          number: 46,
          name: 'سورۂ الاحقاف',
          rukus: 4,
          first: 'عبدیتِ کاملہ کا اعلان',
          last: 'خاموشی، سماع کا دروازہ',
        ),
        'muhammad': (
          number: 47,
          name: 'سورۂ محمد',
          rukus: 4,
          first: 'جن کا حال سنوار دیا گیا',
          last: 'اللہ غنی، تم فقیر',
        ),
        'fath': (
          number: 48,
          name: 'سورۂ الفتح',
          rukus: 4,
          first: 'فتحِ مبین اور سکینہ',
          last: 'سچا خواب اور اصحاب کی تصویر',
        ),
        'hujurat': (
          number: 49,
          name: 'سورۂ الحجرات',
          rukus: 2,
          first: 'ادبِ حضور اور ایمانی اخوت',
          last: 'عزتِ انسان اور ایمان کی حقیقت',
        ),
        'qaf': (
          number: 50,
          name: 'سورۂ قٓ',
          rukus: 3,
          first: 'ہر سانس ایک نئی پیدائش',
          last: 'مزید کا راز اور صاحبِ قلب',
        ),
        'dhariyat': (
          number: 51,
          name: 'سورۂ الذاریات',
          rukus: 3,
          first: 'آفاق و انفس کی نشانیاں',
          last: 'اللہ کی طرف فرار',
        ),
        'tur': (
          number: 52,
          name: 'سورۂ الطور',
          rukus: 2,
          first: 'طور کی قسم اور البر الرحیم',
          last: 'ہماری آنکھوں کے سامنے',
        ),
        'najm': (
          number: 53,
          name: 'سورۂ النجم',
          rukus: 3,
          first: 'معراج اور ادبِ نگاہ',
          last: 'سعی، منتہیٰ اور سجدہ',
        ),
        'qamar': (
          number: 54,
          name: 'سورۂ القمر',
          rukus: 3,
          first: 'شقِ قمر اور یاد دہانی',
          last: 'قدر، کن اور مقعدِ صدق',
        ),
        'rahman': (
          number: 55,
          name: 'سورۂ الرحمٰن',
          rukus: 3,
          first: 'رحمٰن نے قرآن سکھایا',
          last: 'دو باغ اور بابرکت نام',
        ),
        'waqiah': (
          number: 56,
          name: 'سورۂ الواقعہ',
          rukus: 3,
          first: 'واقعہ اور تین جماعتیں',
          last: 'کتابِ مکنون اور حق الیقین',
        ),
        'hadid': (
          number: 57,
          name: 'سورۂ الحدید',
          rukus: 4,
          first: 'اول و آخر، ظاہر و باطن',
          last: 'رہبانیت اور چلنے کا نور',
        ),
        'mujadilah': (
          number: 58,
          name: 'سورۂ المجادلہ',
          rukus: 3,
          first: 'فریاد جو سنی گئی',
          last: 'فراموشیِ ذکر اور حزب اللہ',
        ),
        'hashr': (
          number: 59,
          name: 'سورۂ الحشر',
          rukus: 3,
          first: 'ایثار اور بے کینہ دل',
          last: 'نسیانِ نفس اور اسماءِ حسنیٰ',
        ),
        'mumtahanah': (
          number: 60,
          name: 'سورۂ الممتحنہ',
          rukus: 2,
          first: 'اسوۂ ابراہیم اور دعائے توکل',
          last: 'نیکی، انصاف اور بیعتِ مومنات',
        ),
        'saff': (
          number: 61,
          name: 'سورۂ الصف',
          rukus: 2,
          first: 'صدقِ قول اور بشارتِ احمد',
          last: 'تجارتِ نجات اور انصارِ الٰہی',
        ),
        'jumuah': (
          number: 62,
          name: 'سورۂ الجمعہ',
          rukus: 2,
          first: 'تلاوت، تزکیہ اور حکمت',
          last: 'ندائے جمعہ اور ذکرِ کثیر',
        ),
        'munafiqun': (
          number: 63,
          name: 'سورۂ المنافقون',
          rukus: 2,
          first: 'سچا کلمہ، جھوٹی گواہی',
          last: 'ذکر، انفاق اور مہلت',
        ),
        'taghabun': (
          number: 64,
          name: 'سورۂ التغابن',
          rukus: 2,
          first: 'ایک خلق، دو رخ',
          last: 'ایمان اور ہدایتِ قلب',
        ),
        'talaq': (
          number: 65,
          name: 'سورۂ الطلاق',
          rukus: 2,
          first: 'تقویٰ اور کشادگی کی راہ',
          last: 'طبقات میں اترتا امر',
        ),
        'tahrim': (
          number: 66,
          name: 'سورۂ التحریم',
          rukus: 2,
          first: 'خانۂ نبوت اور دعوتِ توبہ',
          last: 'توبۂ نصوح اور چار مثالیں',
        ),
        'mulk': (
          number: 67,
          name: 'سورۂ الملک',
          rukus: 2,
          first: 'بادشاہی اسی کے ہاتھ میں',
          last: 'رحمٰن کے تھامے ہوئے پرندے',
        ),
        'qalam': (
          number: 68,
          name: 'سورۂ القلم',
          rukus: 2,
          first: 'قلم، خلقِ عظیم اور باغ والے',
          last: 'سجدے کی پکار اور صاحبِ حوت',
        ),
        'haqqah': (
          number: 69,
          name: 'سورۂ الحاقہ',
          rukus: 2,
          first: 'الحاقہ، گوشِ واعیہ اور دو نامے',
          last: 'دیدہ و نادیدہ اور حق الیقین',
        ),
        'maarij': (
          number: 70,
          name: 'سورۂ المعارج',
          rukus: 2,
          first: 'زینوں کا رب اور دائم نمازی',
          last: 'مشرقوں اور مغربوں کا رب',
        ),
        'nuh': (
          number: 71,
          name: 'سورۂ نوح',
          rukus: 2,
          first: 'رات دن کی پکار اور استغفار',
          last: 'پانچ نام اور جامع دعا',
        ),
        'jinn': (
          number: 72,
          name: 'سورۂ الجن',
          rukus: 2,
          first: 'جنوں کا سماع اور عبدیت',
          last: 'غیب کا امین رسول',
        ),
        'muzzammil': (
          number: 73,
          name: 'سورۂ المزمل',
          rukus: 2,
          first: 'قیامِ شب، ترتیل اور تبتل',
          last: 'تخفیف کی رحمت',
        ),
        'muddaththir': (
          number: 74,
          name: 'سورۂ المدثر',
          rukus: 2,
          first: 'قیام، تکبیر اور فتنۂ عدد',
          last: 'گروی جانیں اور دو مشیتیں',
        ),
        'qiyamah': (
          number: 75,
          name: 'سورۂ القیامہ',
          rukus: 2,
          first: 'نفسِ لوامہ اور دیدارِ رب',
          last: 'انسان بے مہار نہیں',
        ),
        'dahr': (
          number: 76,
          name: 'سورۂ الدہر',
          rukus: 2,
          first: 'نامذکور سے شرابِ طہور تک',
          last: 'دو مشیتیں، ایک راستہ',
        ),
        'mursalat': (
          number: 77,
          name: 'سورۂ المرسلات',
          rukus: 2,
          first: 'قسمیں، پیمانہ اور یومِ فصل',
          last: 'سایے، چشمے اور رکوع کی پکار',
        ),
        'naba': (
          number: 78,
          name: 'سورۂ النبا',
          rukus: 2,
          first: 'بڑی خبر اور سراب پہاڑ',
          last: 'رب کی طرف ٹھکانا',
        ),
        'naziat': (
          number: 79,
          name: 'سورۂ النازعات',
          rukus: 2,
          first: 'کیا تو پاک ہونا چاہتا ہے؟',
          last: 'دو راستے، دو ٹھکانے',
        ),
        'abasa': (
          number: 80,
          name: 'سورۂ عبس',
          rukus: 1,
          first: 'طالب کی قدر و منزلت',
          last: 'طالب کی قدر و منزلت',
        ),
        'takwir': (
          number: 81,
          name: 'سورۂ التکویر',
          rukus: 1,
          first: 'جان کی حاضری، صبح کی سانس',
          last: 'جان کی حاضری، صبح کی سانس',
        ),
        'infitar': (
          number: 82,
          name: 'سورۂ الانفطار',
          rukus: 1,
          first: 'ربِّ کریم کا پیار بھرا عتاب',
          last: 'ربِّ کریم کا پیار بھرا عتاب',
        ),
        'mutaffifin': (
          number: 83,
          name: 'سورۂ المطففین',
          rukus: 1,
          first: 'ناپ تول، زنگ اور تسنیم',
          last: 'ناپ تول، زنگ اور تسنیم',
        ),
        'inshiqaq': (
          number: 84,
          name: 'سورۂ الانشقاق',
          rukus: 1,
          first: 'رب کی طرف کدح',
          last: 'رب کی طرف کدح',
        ),
        'buruj': (
          number: 85,
          name: 'سورۂ البروج',
          rukus: 1,
          first: 'خندق کی آگ اور ودود رب',
          last: 'خندق کی آگ اور ودود رب',
        ),
        'tariq': (
          number: 86,
          name: 'سورۂ الطارق',
          rukus: 1,
          first: 'رات کا دستک دینے والا تارا',
          last: 'رات کا دستک دینے والا تارا',
        ),
        'ala': (
          number: 87,
          name: 'سورۂ الاعلیٰ',
          rukus: 1,
          first: 'ربِّ اعلیٰ کی تسبیح',
          last: 'ربِّ اعلیٰ کی تسبیح',
        ),
        'ghashiyah': (
          number: 88,
          name: 'سورۂ الغاشیہ',
          rukus: 1,
          first: 'یاد دلانے والا، داروغہ نہیں',
          last: 'یاد دلانے والا، داروغہ نہیں',
        ),
        'fajr': (
          number: 89,
          name: 'سورۂ الفجر',
          rukus: 1,
          first: 'نفسِ مطمئنہ کی واپسی',
          last: 'نفسِ مطمئنہ کی واپسی',
        ),
        'balad': (
          number: 90,
          name: 'سورۂ البلد',
          rukus: 1,
          first: 'دو راہیں اور دشوار گھاٹی',
          last: 'دو راہیں اور دشوار گھاٹی',
        ),
        'shams': (
          number: 91,
          name: 'سورۂ الشمس',
          rukus: 1,
          first: 'نفس کا تزکیہ اور تدسیہ',
          last: 'نفس کا تزکیہ اور تدسیہ',
        ),
        'layl': (
          number: 92,
          name: 'سورۂ اللیل',
          rukus: 1,
          first: 'عطا کی راہ، رضا کی منزل',
          last: 'عطا کی راہ، رضا کی منزل',
        ),
        'duha': (
          number: 93,
          name: 'سورۂ الضحیٰ',
          rukus: 1,
          first: 'تیرے رب نے نہیں چھوڑا',
          last: 'تیرے رب نے نہیں چھوڑا',
        ),
        'inshirah': (
          number: 94,
          name: 'سورۂ الانشراح',
          rukus: 1,
          first: 'سینے کی کشادگی',
          last: 'سینے کی کشادگی',
        ),
        'tin': (
          number: 95,
          name: 'سورۂ التین',
          rukus: 1,
          first: 'احسنِ تقویم کی امانت',
          last: 'احسنِ تقویم کی امانت',
        ),
        'alaq': (
          number: 96,
          name: 'سورۂ العلق',
          rukus: 1,
          first: 'نام، قلم اور سجدہ',
          last: 'نام، قلم اور سجدہ',
        ),
        'qadr': (
          number: 97,
          name: 'سورۂ القدر',
          rukus: 1,
          first: 'شبِ قدر اور دل کی رات',
          last: 'شبِ قدر اور دل کی رات',
        ),
        'bayyinah': (
          number: 98,
          name: 'سورۂ البینہ',
          rukus: 1,
          first: 'بیّنہ سے رضا تک',
          last: 'بیّنہ سے رضا تک',
        ),
        'zalzalah': (
          number: 99,
          name: 'سورۂ الزلزال',
          rukus: 1,
          first: 'زمین کی گواہی',
          last: 'زمین کی گواہی',
        ),
        'adiyat': (
          number: 100,
          name: 'سورۂ العادیات',
          rukus: 1,
          first: 'ہانپتے گھوڑے اور ناشکرا دل',
          last: 'ہانپتے گھوڑے اور ناشکرا دل',
        ),
        'qariah': (
          number: 101,
          name: 'سورۂ القارعہ',
          rukus: 1,
          first: 'دستک، پروانے اور ترازو',
          last: 'دستک، پروانے اور ترازو',
        ),
        'takathur': (
          number: 102,
          name: 'سورۂ التکاثر',
          rukus: 1,
          first: 'گنتی کی غفلت، یقین کی آنکھ',
          last: 'گنتی کی غفلت، یقین کی آنکھ',
        ),
        'asr': (
          number: 103,
          name: 'سورۂ العصر',
          rukus: 1,
          first: 'وقت، خسارہ اور چار شرطیں',
          last: 'وقت، خسارہ اور چار شرطیں',
        ),
        'humazah': (
          number: 104,
          name: 'سورۂ الہمزہ',
          rukus: 1,
          first: 'طعنہ، مال اور حطمہ',
          last: 'طعنہ، مال اور حطمہ',
        ),
        'fil': (
          number: 105,
          name: 'سورۂ الفیل',
          rukus: 1,
          first: 'ہاتھی والے اور گھر کا رب',
          last: 'ہاتھی والے اور گھر کا رب',
        ),
        'quraish': (
          number: 106,
          name: 'سورۂ قریش',
          rukus: 1,
          first: 'ایلاف، نعمت اور بندگی',
          last: 'ایلاف، نعمت اور بندگی',
        ),
        'maun': (
          number: 107,
          name: 'سورۂ الماعون',
          rukus: 1,
          first: 'انکارِ جزا کی نشانیاں',
          last: 'انکارِ جزا کی نشانیاں',
        ),
        'kawthar': (
          number: 108,
          name: 'سورۂ الکوثر',
          rukus: 1,
          first: 'عطا، شکر اور بقا',
          last: 'عطا، شکر اور بقا',
        ),
        'kafirun': (
          number: 109,
          name: 'سورۂ الکافرون',
          rukus: 1,
          first: 'عبادت میں دو ٹوک جدائی',
          last: 'عبادت میں دو ٹوک جدائی',
        ),
        'nasr': (
          number: 110,
          name: 'سورۂ النصر',
          rukus: 1,
          first: 'فتح پر عاجزی کا سجدہ',
          last: 'فتح پر عاجزی کا سجدہ',
        ),
        'lahab': (
          number: 111,
          name: 'سورۂ اللہب',
          rukus: 1,
          first: 'ہاتھوں کی کمائی کا انجام',
          last: 'ہاتھوں کی کمائی کا انجام',
        ),
        'ikhlas': (
          number: 112,
          name: 'سورۂ الاخلاص',
          rukus: 1,
          first: 'احدِ بے ہمتا کی تنزیہ',
          last: 'احدِ بے ہمتا کی تنزیہ',
        ),
        'falaq': (
          number: 113,
          name: 'سورۂ الفلق',
          rukus: 1,
          first: 'سپیدۂ سحر کی پناہ',
          last: 'سپیدۂ سحر کی پناہ',
        ),
        'nas': (
          number: 114,
          name: 'سورۂ الناس',
          rukus: 1,
          first: 'انسانوں کے رب کی پناہ',
          last: 'انسانوں کے رب کی پناہ',
        ),
      };

  bundled.forEach((id, want) {
    test(
      '$id parses with ${want.rukus} ordered rukus and full front matter',
      () async {
        final surah = await service.loadSurah(id);
        expect(surah, isNotNull, reason: id);

        expect(
          surah!.rukus.map((r) => r.number).toList(),
          List<int>.generate(want.rukus, (i) => i + 1),
        );
        expect(surah.surahNumber, want.number);
        expect(surah.nameUrdu, want.name);
        expect(surah.titleUrdu, 'تفسیرِ ابنِ عربی');
        expect(surah.basmala, contains('بِسْمِ'));
        expect(surah.prefaceHtml, isNotEmpty);
        expect(surah.key, isNotEmpty);
        expect(surah.colophonHtml, isNotEmpty);

        // The preface carries highlighted terms the reader styles lapis.
        expect(surah.prefaceHtml.join(), contains('class="hl"'));

        expect(surah.rukus.first.titleUrdu, want.first);
        expect(surah.rukus.last.titleUrdu, want.last);

        for (final r in surah.rukus) {
          expect(r.titleUrdu, isNotEmpty, reason: '$id ruku ${r.number} title');
          expect(r.ayahBlock, isNotEmpty, reason: '$id ruku ${r.number} ayah');
          expect(
            r.glossary,
            isNotEmpty,
            reason: '$id ruku ${r.number} glossary',
          );
          expect(
            r.ordinalUrdu,
            contains('رکوع'),
            reason: '$id ruku ${r.number}',
          );
          // Normally a range (`۱ تا ۶`); a ruku that is a single ayah
          // carries its own label instead (`آیت ۲۰`).
          expect(
            r.ayahRangeUrdu,
            anyOf(contains('تا'), startsWith('آیت')),
            reason: '$id ruku ${r.number}',
          );
        }
      },
    );

    test('$id ruku bodies load and keep their ayah spans', () async {
      for (var n = 1; n <= want.rukus; n++) {
        final html = await service.loadRukuHtml(id, n);
        expect(html, isNotNull, reason: '$id ruku $n');
        expect(html!.trim(), startsWith('<p>'), reason: '$id ruku $n');
        expect(html.contains('class="ayah"'), isTrue, reason: '$id ruku $n');
      }
      expect(await service.loadRukuHtml(id, want.rukus + 1), isNull);
    });
  });

  test(
    'Surah Yusuf parses with 12 ordered rukus and full front matter',
    () async {
      final surah = await service.loadSurah('yusuf');
      expect(surah, isNotNull);

      expect(surah!.rukus.length, 12);
      expect(surah.rukus.first.number, 1);
      expect(surah.rukus.last.number, 12);
      expect(
        surah.rukus.map((r) => r.number).toList(),
        List<int>.generate(12, (i) => i + 1),
      );

      expect(surah.basmala, contains('بِسْمِ'));
      expect(surah.titleUrdu, 'تفسیرِ ابنِ عربی');
      expect(surah.prefaceHtml, hasLength(2));
      expect(surah.key, hasLength(9));
      expect(surah.key.first.meaning, 'عقل');
      expect(surah.colophonHtml, isNotEmpty);
    },
  );

  test('every ruku has a title, ayah block and glossary', () async {
    final surah = await service.loadSurah('yusuf');
    for (final r in surah!.rukus) {
      expect(r.titleUrdu, isNotEmpty, reason: 'ruku ${r.number} title');
      expect(r.ayahBlock, isNotEmpty, reason: 'ruku ${r.number} ayah block');
      expect(r.ordinalUrdu, contains('رکوع'), reason: 'ruku ${r.number}');
      expect(r.ayahRangeUrdu, contains('تا'), reason: 'ruku ${r.number}');
      expect(r.glossary, isNotEmpty, reason: 'ruku ${r.number} glossary');
    }

    expect(surah.rukus.first.titleUrdu, 'خوابِ ازل');
    expect(surah.rukus.first.eyebrow, 'پہلا رکوع · آیات ۱ تا ۶');
  });

  test(
    'ruku body HTML loads for every ruku and keeps the ayah spans',
    () async {
      for (var n = 1; n <= 12; n++) {
        final html = await service.loadRukuHtml('yusuf', n);
        expect(html, isNotNull, reason: 'ruku $n');
        expect(html!.trim(), startsWith('<p>'), reason: 'ruku $n');
      }

      final first = await service.loadRukuHtml('yusuf', 1);
      expect(first!.contains('class="ayah"'), isTrue);
    },
  );

  test('fields rendered as plain Text carry no markup', () async {
    // Bani Israel wraps some ayah blocks in <span class="ayah" data-a="N">.
    // Those fields are rendered with Text, so tags would show literally.
    for (final summary in await service.loadIndex()) {
      final surah = (await service.loadSurah(summary.id))!;
      final plain = <String, String>{
        'basmala': surah.basmala,
        'titleUrdu': surah.titleUrdu,
        'subtitleUrdu': surah.subtitleUrdu,
        'kicker': surah.kicker,
        'nameUrdu': surah.nameUrdu,
        for (final k in surah.key) 'key.${k.term}': '${k.term} ${k.meaning}',
        for (final r in surah.rukus) ...{
          'ruku${r.number}.title': r.titleUrdu,
          'ruku${r.number}.ayahBlock': r.ayahBlock,
          'ruku${r.number}.eyebrow': r.eyebrow,
          for (final g in r.glossary) 'ruku${r.number}.term': g.term,
        },
      };
      plain.forEach((field, value) {
        expect(value, isNot(contains('<')), reason: '${summary.id} $field');
        expect(value, isNot(contains('>')), reason: '${summary.id} $field');
      });
    }
  });

  test('preface, colophon and glossary definitions keep their HTML', () async {
    final yusuf = (await service.loadSurah('yusuf'))!;
    expect(yusuf.prefaceHtml.join(), contains('<p>'));
    final bolded = yusuf.rukus
        .expand((r) => r.glossary)
        .where((g) => g.definitionHtml.contains('<b>'));
    expect(bolded, isNotEmpty);
  });

  test('ruku asset paths are zero-padded', () {
    expect(
      TafseerBundledService.rukuPath('yusuf', 3),
      'assets/tafseer/yusuf/rukus/03.html',
    );
    expect(
      TafseerBundledService.rukuPath('yusuf', 12),
      'assets/tafseer/yusuf/rukus/12.html',
    );
  });

  test('missing content degrades to empty/null rather than throwing', () async {
    expect(await service.loadSurah(''), isNull);
    expect(await service.loadSurah('baqarah'), isNull);
    expect(await service.loadRukuHtml('raad', 0), isNull);
    expect(await service.loadRukuHtml('yusuf', 0), isNull);
    expect(await service.loadRukuHtml('yusuf', 99), isNull);

    final empty = TafseerBundledService(bundle: _EmptyBundle());
    expect(await empty.loadIndex(), isEmpty);
    expect(await empty.loadSurah('yusuf'), isNull);
    expect(await empty.loadRukuHtml('yusuf', 1), isNull);
  });
}
