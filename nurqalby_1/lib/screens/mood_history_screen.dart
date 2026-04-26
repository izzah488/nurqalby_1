import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mood_database.dart';
import '../services/weekly_summary_popup.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  // 0 = Today  |  1 = This Week
  int _selectedPeriod = 1;
  int _touchedIndex   = -1;

  List<Map<String, dynamic>> _moods = [];
  bool _loading = true;

  // ── Emotion colours (distinct from purple theme) ──────────────────────────
  static const _emotionColors = {
    'joy':     Color(0xFFE8A020), // Amber
    'sadness': Color(0xFF2979B8), // Blue
    'anger':   Color(0xFFD32F2F), // Red
    'fear':    Color(0xFF455A64), // Blue-grey
    'disgust': Color(0xFF558B2F), // Dark green
    'surprise':Color(0xFF00897B), // Teal
    'neutral': Color(0xFF78909C), // Grey
  };

  static const _emotionEmoji = {
    'joy':      '😊',
    'sadness':  '😢',
    'anger':    '😠',
    'fear':     '😰',
    'disgust':  '🤢',
    'surprise': '😲',
    'neutral':  '😐',
  };

  // ── Theme constants ───────────────────────────────────────────────────────
  static const _bgColor      = Color(0xFFF8F8FF);
  static const _cardColor    = Color(0xFFEDE5F8);
  static const _accentColor  = Color(0xFF9966CC);
  static const _textDark     = Color(0xFF2D1B4E);
  static const _textMedium   = Color(0xFF7B5EA7);
  static const _borderColor  = Color(0xFFD4B8E8);

  @override
  void initState() {
    super.initState();
    _loadMoods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WeeklySummaryHelper.checkAndShowSundayPopup(context);
    });
  }

  Future<void> _loadMoods() async {
    setState(() => _loading = true);
    final data = _selectedPeriod == 0
        ? await MoodDatabase.instance.getDailyMoods()
        : await MoodDatabase.instance.getWeeklyMoods();
    setState(() {
      _moods        = data;
      _loading      = false;
      _touchedIndex = -1;
    });
  }

  Map<String, int> get _emotionCounts {
    final map = <String, int>{};
    for (final m in _moods) {
      final e = m['emotion'] as String;
      map[e] = (map[e] ?? 0) + 1;
    }
    return map;
  }

  String get _periodLabel {
    final now    = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    if (_selectedPeriod == 0) {
      return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    } else {
      final daysFromMonday = now.weekday - DateTime.monday;
      final monday = DateTime(now.year, now.month, now.day - daysFromMonday);
      final sunday = monday.add(const Duration(days: 6));
      return 'Mon ${monday.day}/${monday.month} – Sun ${sunday.day}/${sunday.month}';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,

      // ── App Bar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,          // bottom nav handles routing
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Mood Journey',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          // ── Period toggle pill ─────────────────────────────────────────
          Container(
            color: _accentColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildToggleButton('Today',     0),
                  _buildToggleButton('This Week', 1),
                ],
              ),
            ),
          ),

          // ── Period label ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: _cardColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _periodLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _accentColor))
                : _moods.isEmpty
                    ? _buildEmpty()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Column(
                          children: [
                            _buildPieChart(),
                            const SizedBox(height: 16),
                            _buildLegend(),
                            const SizedBox(height: 24),
                            _buildSessionList(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─── Toggle button ──────────────────────────────────────────────────────────
  Widget _buildToggleButton(String label, int index) {
    final selected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = index);
          _loadMoods();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _accentColor : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pie chart ──────────────────────────────────────────────────────────────
  Widget _buildPieChart() {
    final counts = _emotionCounts;
    final total  = _moods.length;

    final sections = <PieChartSectionData>[];
    int i = 0;
    for (final entry in counts.entries) {
      final isTouched = i == _touchedIndex;
      final pct = entry.value / total * 100;
      sections.add(PieChartSectionData(
        value: entry.value.toDouble(),
        color: _emotionColors[entry.key] ?? Colors.grey,
        radius: isTouched ? 80 : 65,
        title: '${pct.round()}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
        ),
      ));
      i++;
    }

    final dominantEntry =
        counts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          // Card title
          Text(
            _selectedPeriod == 0 ? "Today's Mood" : "This Week's Mood",
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),

          // Dominant emotion chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              '${_emotionEmoji[dominantEntry.key] ?? '😶'} '
              '${dominantEntry.key[0].toUpperCase()}${dominantEntry.key.substring(1)} is dominant',
              style: const TextStyle(
                color: _textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _touchedIndex =
                              response?.touchedSection?.touchedSectionIndex ?? -1;
                        });
                      },
                    ),
                  ),
                ),
                // Centre label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _emotionEmoji[dominantEntry.key] ?? '😶',
                      style: const TextStyle(fontSize: 28),
                    ),
                    Text(
                      '$total\nsessions',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textMedium,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Legend ─────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    final counts = _emotionCounts;
    final total  = _moods.length;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: counts.entries.map((e) {
          final pct   = (e.value / total * 100).round();
          final color = _emotionColors[e.key] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  _emotionEmoji[e.key] ?? '😶',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
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
                              color: _textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$pct%  (${e.value} sessions)',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / total,
                          minHeight: 7,
                          backgroundColor: _borderColor.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Session list ────────────────────────────────────────────────────────────
  Widget _buildSessionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ..._moods.map((m) {
          final emotion = m['emotion'] as String;
          final cause   = m['cause']   as String;
          final note    = m['note']    as String? ?? '';
          final ts      = DateTime.tryParse(m['timestamp'] as String) ?? DateTime.now();
          final color   = _emotionColors[emotion] ?? Colors.grey;
          final days    = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
          final dayName = days[ts.weekday - 1];
          final timeStr = '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';
          final dateStr = '$dayName  ${ts.day}/${ts.month}/${ts.year}  $timeStr';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Emotion avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      _emotionEmoji[emotion] ?? '😶',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emotion[0].toUpperCase() + emotion.substring(1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cause,
                        style: const TextStyle(
                          color: _textMedium,
                          fontSize: 12,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📝 $note',
                          style: TextStyle(
                            color: _textDark.withOpacity(0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: _textDark.withOpacity(0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final label = _selectedPeriod == 0 ? 'today' : 'this week';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 72,
            color: _textDark.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No moods recorded $label',
            style: const TextStyle(color: _textMedium, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a session to track your emotions.',
            style: TextStyle(
              color: _textDark.withOpacity(0.35),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
