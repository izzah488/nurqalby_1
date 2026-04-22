import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/mood_database.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});
  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  List<Map<String, dynamic>> _moods = [];
  bool _isWeekView = true; // true = Week, false = Day
  int _touchedIndex = -1;

  final Map<String, Color> _emotionColors = {
    'joy':     const Color(0xFFFFD54F),
    'sadness': const Color(0xFF64B5F6),
    'anger':   const Color(0xFFEF5350),
    'fear':    const Color(0xFFAB47BC),
  };

  final Map<String, String> _emotionEmoji = {
    'joy':     '😊',
    'sadness': '😢',
    'anger':   '😠',
    'fear':    '😨',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> data;
    if (_isWeekView) {
      data = await MoodDatabase.instance.getWeeklyMoods();
    } else {
      data = await MoodDatabase.instance.getDailyMoods();
    }
    setState(() => _moods = data);
  }

  // Count how many times each emotion appears
  Map<String, int> get _emotionCounts {
    final counts = <String, int>{};
    for (final m in _moods) {
      final e = m['emotion'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _emotionCounts;
    final total = counts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E57C2),
        foregroundColor: Colors.white,
        title: const Text('My Mood Journey 🌙'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Toggle Buttons ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _toggleBtn(label: 'Today', selected: !_isWeekView, onTap: () {
                    setState(() => _isWeekView = false);
                    _load();
                  }),
                  _toggleBtn(label: 'This Week', selected: _isWeekView, onTap: () {
                    setState(() => _isWeekView = true);
                    _load();
                  }),
                ],
              ),
            ),
          ),

          // ── Period Label ────────────────────────────────────────
          Text(
            _isWeekView ? 'Last 7 Days' : 'Today',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // ── Pie Chart or Empty State ─────────────────────────────
          if (_moods.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      _isWeekView
                          ? 'No moods recorded this week.'
                          : 'No moods recorded today.',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start by entering how you feel!',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Pie Chart
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: _buildSections(counts, total),
                    ),
                  ),
                  // Center label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5E35B1),
                        ),
                      ),
                      const Text(
                        'sessions',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Legend ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: counts.entries.map((entry) {
                  final pct = total > 0
                      ? (entry.value / total * 100).toStringAsFixed(1)
                      : '0';
                  return _legendItem(
                    color: _emotionColors[entry.key] ?? Colors.grey,
                    emoji: _emotionEmoji[entry.key] ?? '',
                    label: entry.key,
                    count: entry.value,
                    percent: pct,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            // ── Recent Sessions List ──────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<String, int> counts, int total) {
    final entries = counts.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = entries[i];
      final pct = total > 0 ? entry.value / total * 100 : 0.0;
      return PieChartSectionData(
        color: _emotionColors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '${pct.toStringAsFixed(0)}%',
        radius: isTouched ? 75 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _toggleBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7E57C2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String emoji,
    required String label,
    required int count,
    required String percent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$emoji ${label[0].toUpperCase()}${label.substring(1)}  $count ($percent%)',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _moods.length,
      itemBuilder: (ctx, i) {
        final m = _moods[i];
        final dt = DateTime.parse(m['timestamp']);
        final emotion = m['emotion'] as String;
        final cause = m['cause'] as String? ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (_emotionColors[emotion] ?? Colors.grey).withOpacity(0.2),
              child: Text(
                _emotionEmoji[emotion] ?? '🌙',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              '${emotion[0].toUpperCase()}${emotion.substring(1)}'
              '${cause.isNotEmpty ? '  •  $cause' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${_dayName(dt.weekday)}, ${dt.day}/${dt.month}/${dt.year}  '
              '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (_emotionColors[emotion] ?? Colors.grey).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emotion[0].toUpperCase() + emotion.substring(1),
                style: TextStyle(
                  fontSize: 11,
                  color: _emotionColors[emotion] ?? Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
