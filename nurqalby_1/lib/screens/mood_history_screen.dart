// lib/screens/mood_history_screen.dart
//
// UPDATED to use MoodCubit instead of raw setState + async calls.
// No login / no user ID needed — data is stored locally per device.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../cubit/mood_cubit.dart';
import '../cubit/mood_state.dart';
import '../services/weekly_summary_popup.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the cubit and immediately load "This Week" (period = 1)
    return BlocProvider(
      create: (_) => MoodCubit()..loadMoods(1),
      child: const _MoodHistoryView(),
    );
  }
}

// ─── Internal view ───────────────────────────────────────────────────────────
class _MoodHistoryView extends StatefulWidget {
  const _MoodHistoryView();

  @override
  State<_MoodHistoryView> createState() => _MoodHistoryViewState();
}

class _MoodHistoryViewState extends State<_MoodHistoryView> {
  int _touchedIndex = -1;

  // ── Emotion colours ──────────────────────────────────────────────────────────
  static const _emotionColors = {
    'joy':      Color(0xFFE8A020),
    'sadness':  Color(0xFF2979B8),
    'anger':    Color(0xFFD32F2F),
    'fear':     Color(0xFF455A64),
    'disgust':  Color(0xFF558B2F),
    'surprise': Color(0xFF00897B),
    'neutral':  Color(0xFF78909C),
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

  static const _bgColor     = Color(0xFFF8F8FF);
  static const _cardColor   = Color(0xFFEDE5F8);
  static const _accentColor = Color(0xFF9966CC);
  static const _textDark    = Color(0xFF2D1B4E);
  static const _textMedium  = Color(0xFF7B5EA7);
  static const _borderColor = Color(0xFFD4B8E8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WeeklySummaryHelper.checkAndShowSundayPopup(context);
    });
  }

  String _periodLabel(int period) {
    final now    = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    if (period == 0) {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Mood Journey',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<MoodCubit, MoodState>(
        builder: (context, state) {
          // ── Determine selected period for the toggle display ────────────────
          final selectedPeriod =
              state is MoodLoaded ? state.selectedPeriod : 1;

          return Column(
            children: [
              // ── Period toggle ─────────────────────────────────────────────
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
                      _buildToggleButton(context, 'Today',     0, selectedPeriod),
                      _buildToggleButton(context, 'This Week', 1, selectedPeriod),
                    ],
                  ),
                ),
              ),

              // ── Period label ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: _cardColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _periodLabel(selectedPeriod),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _textMedium, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),

              // ── Main content area ────────────────────────────────────────
              Expanded(
                child: _buildBody(state),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Body depends on state ───────────────────────────────────────────────────
  Widget _buildBody(MoodState state) {
    if (state is MoodLoading || state is MoodInitial) {
      return const Center(
          child: CircularProgressIndicator(color: _accentColor));
    }
    if (state is MoodError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMedium)),
        ),
      );
    }
    if (state is MoodLoaded) {
      if (state.moods.isEmpty) return _buildEmpty(state.selectedPeriod);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            _buildPieChart(state.moods),
            const SizedBox(height: 16),
            _buildLegend(state.moods),
            const SizedBox(height: 24),
            _buildSessionList(state.moods),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  // ─── Toggle button ───────────────────────────────────────────────────────────
  Widget _buildToggleButton(
      BuildContext context, String label, int index, int selectedPeriod) {
    final selected = selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        // All state logic goes through the cubit — no setState here!
        onTap: () => context.read<MoodCubit>().loadMoods(index),
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

  // ─── Pie Chart ───────────────────────────────────────────────────────────────
  Widget _buildPieChart(List<Map<String, dynamic>> moods) {
    final counts = <String, int>{};
    for (final m in moods) {
      final e = m['emotion'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final total = moods.length;

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
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 55,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.touchedSection
                              ?.touchedSectionIndex ??
                          -1;
                    });
                  },
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_emotionEmoji[dominantEntry.key] ?? '😶',
                  style: const TextStyle(fontSize: 28)),
              Text('$total\nsessions',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _textMedium, fontSize: 12, height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Legend ──────────────────────────────────────────────────────────────────
  Widget _buildLegend(List<Map<String, dynamic>> moods) {
    final counts = <String, int>{};
    for (final m in moods) {
      final e = m['emotion'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final total = moods.length;

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
                Text(_emotionEmoji[e.key] ?? '😶',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key[0].toUpperCase() + e.key.substring(1),
                              style: const TextStyle(
                                  color: _textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text('$pct%  (${e.value} sessions)',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
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

  // ─── Session list ─────────────────────────────────────────────────────────────
  Widget _buildSessionList(List<Map<String, dynamic>> moods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Sessions',
            style: TextStyle(
                color: _textDark, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...moods.map((m) {
          final emotion = m['emotion'] as String;
          final cause   = m['cause']   as String;
          final note    = m['note']    as String? ?? '';
          final ts      = DateTime.tryParse(m['timestamp'] as String) ?? DateTime.now();
          final color   = _emotionColors[emotion] ?? Colors.grey;
          final days    = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
          final timeStr = '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';
          final dateStr = '${days[ts.weekday - 1]}  ${ts.day}/${ts.month}/${ts.year}  $timeStr';

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
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(_emotionEmoji[emotion] ?? '😶',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emotion[0].toUpperCase() + emotion.substring(1),
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(cause,
                          style: const TextStyle(
                              color: _textMedium, fontSize: 12)),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📝 $note',
                            style: TextStyle(
                                color: _textDark.withOpacity(0.45),
                                fontSize: 11)),
                      ],
                      const SizedBox(height: 4),
                      Text(dateStr,
                          style: TextStyle(
                              color: _textDark.withOpacity(0.35),
                              fontSize: 11)),
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

  // ─── Empty state ──────────────────────────────────────────────────────────────
  Widget _buildEmpty(int period) {
    final label = period == 0 ? 'today' : 'this week';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded,
              size: 72, color: _textDark.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No moods recorded $label',
              style: const TextStyle(color: _textMedium, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Start a session to track your emotions.',
              style: TextStyle(
                  color: _textDark.withOpacity(0.35), fontSize: 13)),
        ],
      ),
    );
  }
}