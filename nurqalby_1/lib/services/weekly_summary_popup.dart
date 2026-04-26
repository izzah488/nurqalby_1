import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mood_database.dart';

class WeeklySummaryHelper {
  static const String _baseUrl = 'http://10.186.181.134:8000';

  /// Call this from MoodHistoryScreen's initState.
  /// Shows the popup only on Sundays, once per week.
  static Future<void> checkAndShowSundayPopup(BuildContext context) async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    // Check if already shown this week
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _getWeekKey(now);
    final alreadyShown = prefs.getBool('weekly_popup_$weekKey') ?? false;
    if (alreadyShown) return;

    // Get this week's moods
    final thisMoods = await MoodDatabase.instance.getWeeklyMoods();
    if (thisMoods.isEmpty) return;

    // Get last week's moods for trend comparison
    final lastMoods = await MoodDatabase.instance.getLastWeekMoods();

    // Count emotions this week
    final Map<String, int> counts = {};
    for (final m in thisMoods) {
      final e = m['emotion'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
    }

    // Dominant emotion
    final dominant = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Trend: compare joy% this week vs last week
    final trend = _calculateTrend(thisMoods, lastMoods);

    // Fetch a verse from backend based on dominant emotion
    String verseText = '';
    String verseRef = '';
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': dominant,
          'emotion': dominant,
          'cause': 'general',
        }),
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          verseText = results[0]['verse'] ?? results[0]['text'] ?? '';
          verseRef  = results[0]['reference'] ?? results[0]['surah'] ?? '';
        }
      }
    } catch (_) {
      // Offline fallback verses
      final fallback = {
        'joy':     ['Verily, with every difficulty comes ease.', 'Quran 94:5'],
        'sadness': ['Allah does not burden a soul beyond that it can bear.', 'Quran 2:286'],
        'anger':   ['The strong is not the one who overcomes people; the strong is the one who controls themselves.', 'Hadith — Bukhari'],
        'fear':    ['And He is with you wherever you are.', 'Quran 57:4'],
      };
      verseText = fallback[dominant]?[0] ?? '';
      verseRef  = fallback[dominant]?[1] ?? '';
    }

    // Mark as shown for this week
    await prefs.setBool('weekly_popup_$weekKey', true);

    // Show the popup
    if (context.mounted) {
      _showPopup(context, dominant, trend, verseText, verseRef, counts, thisMoods.length);
    }
  }

  // ─── Trend Calculation ────────────────────────────────────────────────────
  // Wellness score = joy% − average(sadness%, anger%, fear%)
  // Considers ALL 4 emotions. More joy = higher score.
  // More sadness/anger/fear = lower score.
  static double _wellnessScore(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return 0;
    final total = moods.length;
    final joy     = moods.where((m) => m['emotion'] == 'joy').length     / total;
    final sadness = moods.where((m) => m['emotion'] == 'sadness').length / total;
    final anger   = moods.where((m) => m['emotion'] == 'anger').length   / total;
    final fear    = moods.where((m) => m['emotion'] == 'fear').length    / total;
    // Joy is positive, negative emotions pull the score down
    return joy - ((sadness + anger + fear) / 3);
  }

  static String _calculateTrend(
    List<Map<String, dynamic>> thisWeek,
    List<Map<String, dynamic>> lastWeek,
  ) {
    if (lastWeek.isEmpty) return 'stable';

    final scoreThis = _wellnessScore(thisWeek);
    final scoreLast = _wellnessScore(lastWeek);
    final diff = scoreThis - scoreLast;

    if (diff > 0.10) return 'improving';
    if (diff < -0.10) return 'worsening';
    return 'stable';
  }

  // ─── Week Key (e.g. "2025_17") ────────────────────────────────────────────
  static String _getWeekKey(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final weekNum = ((date.difference(startOfYear).inDays) / 7).floor();
    return '${date.year}_$weekNum';
  }

  // ─── Show Popup Dialog ────────────────────────────────────────────────────
  static void _showPopup(
    BuildContext context,
    String dominant,
    String trend,
    String verse,
    String reference,
    Map<String, int> counts,
    int total,
  ) {
    const emotionEmoji = {
      'joy':     '😊',
      'sadness': '😢',
      'anger':   '😠',
      'fear':    '😰',
    };
    const emotionColor = {
      'joy':     Color(0xFFFFC107),
      'sadness': Color(0xFF42A5F5),
      'anger':   Color(0xFFEF5350),
      'fear':    Color(0xFFAB47BC),
    };

    final trendInfo = {
      'improving': {
        'icon':    '🌟',
        'label':   'Improving',
        'color':   const Color(0xFF4CAF50),
        'message': 'You are making good emotional progress this week. Keep going!',
      },
      'stable': {
        'icon':    '🌿',
        'label':   'Stable',
        'color':   const Color(0xFF29B6F6),
        'message': 'Your emotions remain consistent this week. Stay grounded.',
      },
      'worsening': {
        'icon':    '💙',
        'label':   'Take care',
        'color':   const Color(0xFF7E57C2),
        'message': 'Take some time to care for yourself — support is always here.',
      },
    }[trend]!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1A2E),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  '🌙  Weekly Mood Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'End of the week reflection',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // ── Trend Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (trendInfo['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (trendInfo['color'] as Color).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Text(trendInfo['icon'] as String,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trendInfo['label'] as String,
                            style: TextStyle(
                              color: trendInfo['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trendInfo['message'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Emotion Breakdown ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This week ($total sessions)',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...counts.entries.map((e) {
                final pct = (e.value / total * 100).round();
                final color = emotionColor[e.key] ?? Colors.grey;
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
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$pct%  (${e.value})',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.value / total,
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation(color),
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

              // ── Verse ──
              if (verse.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '✨  Verse for You',
                        style: TextStyle(
                          color: Color(0xFFD4A017),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"$verse"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      if (reference.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '— $reference',
                          style: const TextStyle(
                            color: Color(0xFFD4A017),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Close Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A017),
                    foregroundColor: Colors.black,
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
