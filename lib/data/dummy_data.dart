import '../models/irshad_model.dart';
import '../models/murshad_model.dart';
import '../models/sabaq_model.dart';

class DummyData {
  static const mosqueDomeGold =
      'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=800';
  static const archwayCorridor =
      'https://images.unsplash.com/photo-1580418827493-f2b22c0a76cb?w=800';
  static const blueMosqueDusk =
      'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800';
  static const shrineLanterns =
      'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?w=800';
  static const tilePattern =
      'https://images.unsplash.com/photo-1585036156171-384164a8c675?w=800';
  static const calligraphyClose =
      'https://images.unsplash.com/photo-1597673030062-0a0f1a801a31?w=800';
  static const rosePetals =
      'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=800';
  static const candleFlame =
      'https://images.unsplash.com/photo-1603006905003-be475563bc59?w=800';
  static const mistyMountain =
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800';

  static const galleryImages = <String>[
    mosqueDomeGold,
    archwayCorridor,
    blueMosqueDusk,
    shrineLanterns,
    tilePattern,
    calligraphyClose,
    rosePetals,
    candleFlame,
    mistyMountain,
  ];

  static const sabaqList = <SabaqModel>[
    SabaqModel(
      id: 's1',
      title: 'Sabaq 01 — Adab-e-Dil',
      subtitle: 'Foundations of inner courtesy',
      pageCount: 3,
      coverImageUrl: mosqueDomeGold,
      isLocked: false,
      pages: [
        SabaqPage(
          chapterTitle: 'Adab of Seeking',
          urdu:
              'جو دل ادب سیکھ لیتا ہے، وہی دل نور کو پہچانتا ہے۔\n'
              'خاموشی میں نیت کی صفائی ہوتی ہے، اور صفائی میں قرب کی خوشبو۔',
          english:
              'When the heart learns adab, it begins to recognize light.\n'
              'In silence, intention is purified; and in purification, nearness gains fragrance.',
        ),
        SabaqPage(
          chapterTitle: 'Remembering with Breath',
          urdu:
              'ذکر سانس کے ساتھ ہو تو دل کے دروازے کھلتے ہیں۔\n'
              'سانس کا ہر آنا جانا امانت ہے—اسے اللہ کے نام سے آراستہ کرو۔',
          english:
              'When remembrance flows with the breath, the doors of the heart open.\n'
              'Every inhale and exhale is a trust—adorn it with the Name of Allah.',
        ),
        SabaqPage(
          chapterTitle: 'Gentleness',
          urdu:
              'نرمی محبت کی زبان ہے، اور محبت روح کی غذا۔\n'
              'جو نرم ہوتا ہے، وہی قریب ہوتا ہے۔',
          english:
              'Gentleness is the language of love, and love is nourishment for the soul.\n'
              'The one who is gentle is the one who is near.',
        ),
      ],
    ),
    SabaqModel(
      id: 's2',
      title: 'Sabaq 02 — Safar',
      subtitle: 'The inward journey',
      pageCount: 12,
      coverImageUrl: archwayCorridor,
      isLocked: true,
      pages: [],
    ),
    SabaqModel(
      id: 's3',
      title: 'Sabaq 03 — Tawba',
      subtitle: 'Returning to the Beloved',
      pageCount: 10,
      coverImageUrl: blueMosqueDusk,
      isLocked: true,
      pages: [],
    ),
    SabaqModel(
      id: 's4',
      title: 'Sabaq 04 — Sabr',
      subtitle: 'Patience and illumination',
      pageCount: 14,
      coverImageUrl: shrineLanterns,
      isLocked: true,
      pages: [],
    ),
    SabaqModel(
      id: 's5',
      title: 'Sabaq 05 — Ishq',
      subtitle: 'Love as purification',
      pageCount: 16,
      coverImageUrl: calligraphyClose,
      isLocked: true,
      pages: [],
    ),
  ];

  static const irshadList = <IrshadModel>[
    IrshadModel(
      dateLabel: '14 Apr 2026',
      urdu: 'دل کی روشنی نیت کی سچائی سے پیدا ہوتی ہے۔',
      english: 'The heart’s light is born from the truthfulness of intention.',
    ),
    IrshadModel(
      dateLabel: '13 Apr 2026',
      urdu: 'جو اپنے رب کو یاد رکھتا ہے، وہ خود کو کھو کر پا لیتا ہے۔',
      english:
          'Who remembers their Lord finds themselves by being lost in Him.',
    ),
    IrshadModel(
      dateLabel: '12 Apr 2026',
      urdu: 'خاموشی میں دل کی گفتگو سنائی دیتی ہے۔',
      english: 'In silence, the heart’s conversation becomes audible.',
    ),
  ];

  static const shijraLine = <MurshadModel>[
    MurshadModel(name: 'Hazrat Abdul Qadir Jilani (RA)', dates: '470–561 AH'),
    MurshadModel(name: 'Hazrat Sultan Bahoo (RA)', dates: '1039–1102 AH'),
    MurshadModel(
      name: 'Hazrat Khawaja Ghulam Farid (RA)',
      dates: '1261–1319 AH',
    ),
    MurshadModel(
      name: 'Hazrat Khawaja Saeen Sufi Nisar Ahmad Khaliquei',
      dates: 'Contemporary',
    ),
  ];

  static const memberName = 'Umair';
  static const memberRef = 'AN-01984';
  static const memberSilsila = 'Qadri';
  static const joinDate = 'Joined: 2025';

  static const asbaqList = <SabaqModel>[
    SabaqModel(
      id: 'a1',
      title: 'Pehla Sabaq',
      subtitle: '',
      pageCount: 24,
      coverImageUrl: mosqueDomeGold,
      isLocked: false,
      urduTitle: 'پہلا سبق',
      lessonNumber: 1,
      pages: [
        SabaqPage(
          chapterTitle: 'Pehla Sabaq',
          urdu:
              'اسباقِ طریقت کا پہلا قدم دل کی حاضری ہے۔\n'
              'جب دل حاضر ہوتا ہے تو نور قریب محسوس ہوتا ہے۔',
          english:
              'The first step of the lessons of the path is presence of heart.\n'
              'When the heart is present, light feels near.',
        ),
      ],
    ),
    SabaqModel(
      id: 'a2',
      title: 'Doosra Sabaq',
      subtitle: '',
      pageCount: 20,
      coverImageUrl: archwayCorridor,
      isLocked: true,
      urduTitle: 'دوسرا سبق',
      lessonNumber: 2,
      pages: [],
    ),
    SabaqModel(
      id: 'a3',
      title: 'Teesra Sabaq',
      subtitle: '',
      pageCount: 18,
      coverImageUrl: blueMosqueDusk,
      isLocked: true,
      urduTitle: 'تیسرا سبق',
      lessonNumber: 3,
      pages: [],
    ),
    SabaqModel(
      id: 'a4',
      title: 'Chautha Sabaq',
      subtitle: '',
      pageCount: 22,
      coverImageUrl: shrineLanterns,
      isLocked: true,
      urduTitle: 'چوتھا سبق',
      lessonNumber: 4,
      pages: [],
    ),
    SabaqModel(
      id: 'a5',
      title: 'Paanchwa Sabaq',
      subtitle: '',
      pageCount: 16,
      coverImageUrl: calligraphyClose,
      isLocked: true,
      urduTitle: 'پانچواں سبق',
      lessonNumber: 5,
      pages: [],
    ),
    SabaqModel(
      id: 'a6',
      title: 'Chatta Sabaq',
      subtitle: '',
      pageCount: 19,
      coverImageUrl: rosePetals,
      isLocked: true,
      urduTitle: 'چھٹا سبق',
      lessonNumber: 6,
      pages: [],
    ),
    SabaqModel(
      id: 'a7',
      title: 'Saatwa Sabaq',
      subtitle: '',
      pageCount: 21,
      coverImageUrl: tilePattern,
      isLocked: true,
      urduTitle: 'ساتواں سبق',
      lessonNumber: 7,
      pages: [],
    ),
  ];
}
