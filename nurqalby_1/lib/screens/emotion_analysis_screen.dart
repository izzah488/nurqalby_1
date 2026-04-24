import 'package:flutter/material.dart';
import 'emotion_screen.dart';

class EmotionAnalysisScreen extends StatefulWidget {
  final String userText;
  final String detectedEmotion;
  final double confidence;
  final Map<String, double>? allScores;

  const EmotionAnalysisScreen({
    super.key,
    required this.userText,
    required this.detectedEmotion,
    required this.confidence,
    this.allScores,
  });

  @override
  State<EmotionAnalysisScreen> createState() => _EmotionAnalysisScreenState();
}

class _EmotionAnalysisScreenState extends State<EmotionAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _barAnimations;

  // Emotion display config — bar colors kept distinct per emotion
  final Map<String, Map<String, dynamic>> _emotionConfig = {
    'sadness': {'label': 'Sadness', 'icon': '😔', 'color': const Color(0xFF2979B8)},
    'fear':    {'label': 'Fear',    'icon': '😨', 'color': const Color(0xFF455A64)},
    'anger':   {'label': 'Anger',   'icon': '😠', 'color': const Color(0xFFD32F2F)},
    'joy':     {'label': 'Joy',     'icon': '😊', 'color': const Color(0xFFE8A020)},
  };

  final List<String> _emotionOrder = ['joy', 'sadness', 'fear', 'anger'];

  List<MapEntry<String, double>> get _sortedScores {
    final scores = widget.allScores ??
        {widget.detectedEmotion: widget.confidence};
    final filled = <String, double>{};
    for (final key in _emotionOrder) {
      filled[key] = scores[key] ?? 0.0;
    }
    final entries = filled.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final scores = _sortedScores;
    _barAnimations = scores.map((e) {
      return Tween<double>(begin: 0, end: e.value).animate(
        CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
        ),
      );
    }).toList();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = _sortedScores;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4B8E8)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF2D1B4E), size: 20),
                    ),
                  ),
                  // AI badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF9966CC).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFF7B5EA7), size: 13),
                        SizedBox(width: 6),
                        Text('BERT Analysis',
                            style: TextStyle(
                                color: Color(0xFF7B5EA7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Title ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Emotion Analysis',
                  style: TextStyle(
                      color: Color(0xFF2D1B4E),
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                'Here\'s what AI detected from your words.',
                style: const Color(0xFF2D1B4E).withOpacity(0.55) != null
                    ? TextStyle(
                        color: const Color(0xFF2D1B4E).withOpacity(0.55),
                        fontSize: 13)
                    : const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            // ── User text preview ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4B8E8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: Color(0xFF7FB883), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.userText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: const Color(0xFF2D1B4E).withOpacity(0.75),
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Emotion bars ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Column(
                      children: List.generate(scores.length, (i) {
                        final entry = scores[i];
                        final isTop =
                            entry.key == widget.detectedEmotion;
                        final config = _emotionConfig[entry.key]!;
                        final barColor = config['color'] as Color;
                        final animatedValue = _barAnimations[i].value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _EmotionBar(
                            icon: config['icon'] as String,
                            label: config['label'] as String,
                            percentage: entry.value,
                            animatedPercentage: animatedValue,
                            barColor: barColor,
                            isTop: isTop,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),

            // ── Top emotion summary card ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEDE5F8),
                      Color(0xFFF8F8FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF9966CC).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Text(
                      _emotionConfig[widget.detectedEmotion]?['icon'] ?? '🤔',
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dominant emotion detected',
                            style: TextStyle(
                                color: const Color(0xFF2D1B4E).withOpacity(0.5),
                                fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_emotionConfig[widget.detectedEmotion]?['label'] ?? widget.detectedEmotion}'
                            '  •  ${(widget.confidence * 100).toStringAsFixed(1)}% confidence',
                            style: const TextStyle(
                                color: Color(0xFF2D1B4E),
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Next button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmotionScreen(
                          userText: widget.userText,
                          detectedEmotion: widget.detectedEmotion,
                          confidence: widget.confidence,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966CC),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF9966CC).withOpacity(0.4),
                  ),
                  child: const Text(
                    'Select Emotion →',
                    style: TextStyle(
                        color: Color(0xFF2D1B4E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable emotion bar widget ─────────────────────────────────────────────
class _EmotionBar extends StatelessWidget {
  final String icon;
  final String label;
  final double percentage;
  final double animatedPercentage;
  final Color barColor;
  final bool isTop;

  const _EmotionBar({
    required this.icon,
    required this.label,
    required this.percentage,
    required this.animatedPercentage,
    required this.barColor,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final pct    = (percentage * 100).toStringAsFixed(1);
    final animPct = animatedPercentage.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop
            ? barColor.withOpacity(0.12)
            : const Color(0xFFEDE5F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop ? barColor.withOpacity(0.5) : const Color(0xFFD4B8E8),
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: isTop
                          ? const Color(0xFF2D1B4E)
                          : const Color(0xFF2D1B4E).withOpacity(0.8),
                      fontSize: 14,
                      fontWeight:
                          isTop ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                    color: isTop ? barColor : const Color(0xFF2D1B4E).withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              if (isTop) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: barColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Top',
                    style: TextStyle(
                        color: barColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: const Color(0xFF2D1B4E).withOpacity(0.07),
                ),
                FractionallySizedBox(
                  widthFactor: animPct,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withOpacity(0.7),
                          barColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
