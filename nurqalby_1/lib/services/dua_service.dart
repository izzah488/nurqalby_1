class DuaService {
  static const Map<String, List<Map<String, String>>> _duas = {
    'sadness': [
      {
        'arabic':      'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
        'translation': 'O Allah I seek refuge in You from worry and grief',
        'reference':   'Bukhari',
      },
      {
        'arabic':      'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
        'translation': 'O Ever Living O Sustainer in Your mercy I seek relief',
        'reference':   'Tirmidhi',
      },
      {
        'arabic':      'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
        'translation': 'None has the right to be worshipped but You, Glory be to You',
        'reference':   'Quran 21:87',
      },
    ],
    'fear': [
      {
        'arabic':      'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
        'translation': 'Allah is sufficient for us and He is the best disposer of affairs',
        'reference':   'Quran 3:173',
      },
      {
        'arabic':      'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا',
        'translation': 'O Allah there is no ease except what You make easy',
        'reference':   'Ibn Hibban',
      },
      {
        'arabic':      'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ',
        'translation': 'O Allah I ask You for wellbeing',
        'reference':   'Tirmidhi',
      },
    ],
    'anger': [
      {
        'arabic':      'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        'translation': 'I seek refuge with Allah from the accursed devil',
        'reference':   'Bukhari',
      },
      {
        'arabic':      'اللَّهُمَّ أَذْهِبْ غَيْظَ قَلْبِي',
        'translation': 'O Allah remove the anger from my heart',
        'reference':   'Tabarani',
      },
      {
        'arabic':      'رَبِّ اشْرَحْ لِي صَدْرِي',
        'translation': 'My Lord expand my chest for me',
        'reference':   'Quran 20:25',
      },
    ],
    'joy': [
      {
        'arabic':      'الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ',
        'translation': 'Praise be to Allah by whose grace good deeds are completed',
        'reference':   'Ibn Majah',
      },
      {
        'arabic':      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        'translation': 'Glory be to Allah and praise be to Him',
        'reference':   'Bukhari',
      },
      {
        'arabic':      'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ',
        'translation': 'O Allah help me to remember You and be grateful to You',
        'reference':   'Abu Dawud',
      },
    ],
  };

  static List<Map<String, String>> getDuasByEmotion(String emotion) {
    return _duas[emotion.toLowerCase()] ?? _duas['sadness']!;
  }
}