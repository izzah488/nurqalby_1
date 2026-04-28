import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mood_database.dart';
import '../services/dua_service.dart';

class WeeklySummaryHelper {
  // ─── Local Verses by Emotion ──────────────────────────────────────────────
  // These are sourced from the local verses database — no internet needed.
  static const Map<String, List<Map<String, String>>> _verses = {
    'joy': [
      {
        'text': 'And your Lord is going to give you, and you will be satisfied.',
        'ref':  'Quran 93:5',
      },
      {
        'text': 'So remember Me; I will remember you. And be grateful to Me and do not deny Me.',
        'ref':  'Quran 2:152',
      },
      {
        'text': 'And He found you lost and guided you.',
        'ref':  'Quran 93:7',
      },
    ],
    'sadness': [
      {
        'text': 'For indeed, with hardship will be ease. Indeed, with hardship will be ease.',
        'ref':  'Quran 94:5–6',
      },
      {
        'text': 'Allah does not burden a soul beyond that it can bear.',
        'ref':  'Quran 2:286',
      },
      {
        'text': 'Unquestionably, by the remembrance of Allah hearts are assured.',
        'ref':  'Quran 13:28',
      },
    ],
    'anger': [
      {
        'text': 'And those who restrain anger and who pardon the people — and Allah loves the doers of good.',
        'ref':  'Quran 3:134',
      },
      {
        'text': 'And if an evil suggestion comes to you from Satan, then seek refuge in Allah. Indeed, He is Hearing and Knowing.',
        'ref':  'Quran 7:200',
      },
      {
        'text': 'The strong is not the one who overcomes people; the strong is the one who controls themselves while in anger.',
        'ref':  'Hadith — Bukhari',
      },
    ],
    'fear': [
      {
        'text': 'And He is with you wherever you are. And Allah, of what you do, is Seeing.',
        'ref':  'Quran 57:4',
      },
      {
        'text': 'Allah is sufficient for us, and He is the best Disposer of affairs.',
        'ref':  'Quran 3:173',
      },
      {
        'text': 'Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.',
        'ref':  'Quran 39:53',
      },
    ],
  };

  // ─── Emotion-Specific Messages ────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _emotionInfo = {
    'joy': {
      'icon':    '🌟',
      'title':   'Alhamdulillah — A Joyful Week!',
      'message': 'Your heart has been glowing with happiness this week. Continue to be grateful — joy shared with Allah grows even more.',
      'color':   Color(0xFFE8A020),
    },
    'sadness': {
      'icon':    '💙',
      'title':   'Your Heart is Heard',
      'message': 'It seems your heart has been heavy this week. Remember, after every hardship comes ease — twice promised by Allah in Surah 94.',
      'color':   Color(0xFF2979B8),
    },
    'anger': {
      'icon':    '🍃',
      'title':   'Take a Breath, Find Peace',
      'message': 'Strong emotions remind us of our humanity. Seek refuge in Allah and allow His peace to settle in your heart.',
      'color':   Color(0xFF7B5EA7),
    },
    'fear': {
      'icon':    '🤍',
      'title':   'You Are Not Alone',
      'message': 'Allah is always with you — in every worry, every uncertainty. Trust in His plan. He knows what you do not know.',
      'color':   Color(0xFF558B2F),
    },
  };

  // ─── Public Entry Point ───────────────────────────────────────────────────
  /// Call this from MoodHistoryScreen's initState.
  /// Shows the popup only on Sundays, once per week.
  static Future<void> checkAndShowSundayPopup(BuildContext context) async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    final prefs   = await SharedPreferences.getInstance();
    final weekKey = _getWeekKey(now);
    if (prefs.getBool('weekly_popup_$weekKey') ?? false) return;

    // Get this week's moods only — no cross-week comparison
    final thisMoods = await MoodDatabase.instance.getWeeklyMoods();
    if (thisMoods.isEmpty) return;

    // Count emotions this week
    final Map<String, int> counts = {};
    for (final m in thisMoods) {
      final e = m['emotion'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
    }

    // Find the dominant emotion
    final dominant = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .toLowerCase();

    // Pick a local verse and dua based on dominant emotion
    final rng      = Random();
    final verseList = _verses[dominant] ?? _verses['sadness']!;
    final verse     = verseList[rng.nextInt(verseList.length)];
    final duaList   = DuaService.getDuasByEmotion(dominant);
    final dua       = duaList[rng.nextInt(duaList.length)];

    // Mark shown for this week
    await prefs.setBool('weekly_popup_$weekKey', true);

    if (context.mounted) {
      _showPopup(context, dominant, verse, dua, counts, thisMoods.length);
    }
  }

  // ─── Week Key Helper ──────────────────────────────────────────────────────
  static String _getWeekKey(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final weekNum     = ((date.difference(startOfYear).inDays) / 7).floor();
    return '${date.year}_$weekNum';
  }

  // ─── Show Popup Dialog ────────────────────────────────────────────────────
  static void _showPopup(
    BuildContext context,
    String dominant,
    Map<String, String> verse,
    Map<String, String> dua,
    Map<String, int> counts,
    int total,
  ) {
    const emotionEmoji = {
      'joy':     '😊',
      'sadness': '😢',
      'anger':   '😠',
      'fear':    '😰',
      'disgust': '🤢',
      'surprise':'😲',
      'neutral': '😐',
    };
    const emotionColor = {
      'joy':     Color(0xFFE8A020),
      'sadness': Color(0xFF2979B8),
      'anger':   Color(0xFFD32F2F),
      'fear':    Color(0xFF455A64),
      'disgust': Color(0xFF558B2F),
      'surprise':Color(0xFF00897B),
      'neutral': Color(0xFF78909C),
    };

    final info = _emotionInfo[dominant] ?? _emotionInfo['sadness']!;
    final accentColor = info['color'] as Color;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF8F8FF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:        const Color(0xFFEDE5F8),
                  borderRadius: BorderRadius.circular(30),
                  border:       Border.all(color: const Color(0xFFD4B8E8)),
                ),
                child: const Text(
                  '🌙  Weekly Mood Summary',
                  style: TextStyle(
                    color:      Color(0xFF2D1B4E),
                    fontWeight: FontWeight.bold,
                    fontSize:   16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'End of the week reflection',
                style: TextStyle(color: Color(0xFF7B5EA7), fontSize: 12),
              ),
              const SizedBox(height: 20),

              // ── Emotion Banner ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:        accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info['icon'] as String,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info['title'] as String,
                            style: TextStyle(
                              color:      accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize:   14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info['message'] as String,
                            style: const TextStyle(
                              color:    Color(0xFF2D1B4E),
                              fontSize: 12,
                              height:   1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Emotion Breakdown ────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This week ($total sessions)',
                  style: const TextStyle(
                    color:      Color(0xFF7B5EA7),
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...counts.entries.map((e) {
                final pct   = (e.value / total * 100).round();
                final color = emotionColor[e.key] ?? const Color(0xFF9966CC);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(emotionEmoji[e.key] ?? '😶',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key[0].toUpperCase() + e.key.substring(1),
                                  style: const TextStyle(
                                    color:      Color(0xFF2D1B4E),
                                    fontSize:   13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$pct%  (${e.value})',
                                  style: TextStyle(
                                    color:      color,
                                    fontSize:   12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:            e.value / total,
                                minHeight:        6,
                                backgroundColor:  const Color(0xFFEDE5F8),
                                valueColor:       AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Verse (from local database) ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        const Color(0xFFEDE5F8),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: const Color(0xFFD4B8E8)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '✨  Verse for You',
                      style: TextStyle(
                        color:      Color(0xFF9966CC),
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"${verse['text']}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:     Color(0xFF2D1B4E),
                        fontSize:  13,
                        fontStyle: FontStyle.italic,
                        height:    1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${verse['ref']}',
                      style: const TextStyle(
                        color:      Color(0xFF7B5EA7),
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Dua ─────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        const Color(0xFFEDE5F8),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: const Color(0xFFD4B8E8)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🤲  Dua for You',
                      style: TextStyle(
                        color:      Color(0xFF9966CC),
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dua['arabic'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:    Color(0xFF2D1B4E),
                        fontSize: 16,
                        height:   1.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${dua['translation']}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:     Color(0xFF7B5EA7),
                        fontSize:  12,
                        fontStyle: FontStyle.italic,
                        height:    1.5,
                      ),
                    ),
                    if ((dua['reference'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '— ${dua['reference']}',
                        style: const TextStyle(
                          color:    Color(0xFF9966CC),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Close Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'May your week ahead be full of peace 🌙',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
