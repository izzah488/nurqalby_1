import 'dart:math';
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
  List<Animation<double>> _arcAnimations = [];

  // ── Emotion config ─────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _emotionConfig = {
    'joy':     {'label': 'Joy',     'icon': '😊', 'color': const Color(0xFF4CAF50)},
    'sadness': {'label': 'Sadness', 'icon': '😔', 'color': const Color(0xFF2979B8)},
    'fear':    {'label': 'Fear',    'icon': '😨', 'color': const Color(0xFF9B59B6)},
    'anger':   {'label': 'Anger',   'icon': '😠', 'color': const Color(0xFFE53935)},
  };

  final List<String> _emotionOrder = ['joy', 'sadness', 'fear', 'anger'];

  List<MapEntry<String, double>> get _sortedScores {
    final scores = widget.allScores ?? {widget.detectedEmotion: widget.confidence};
    final filled = <String, double>{};
    for (final key in _emotionOrder) {
      filled[key] = scores[key] ?? 0.0;
    }
    return filled.entries.toList();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final scores = _sortedScores;
    _arcAnimations = scores.map((e) {
      return Tween<double>(begin: 0, end: e.value).animate(
        CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
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
    final dominantIcon  = _emotionConfig[widget.detectedEmotion]?['icon'] ?? '🤔';
    final dominantLabel = _emotionConfig[widget.detectedEmotion]?['label'] ?? widget.detectedEmotion;
    final dominantColor = _emotionConfig[widget.detectedEmotion]?['color'] as Color? ?? const Color(0xFF8E6BBE);

    return Scaffold(
      body: Stack(
        children: [
          // ── Purple marble background ──────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundanalysis.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Soft white overlay for readability ───────────────────────
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.25),
            ),
          ),

          // ── Decorative circles ───────────────────────────────────────
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF9B59B6).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header row ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.80),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4B8E8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Color(0xFF2D1B4E), size: 20),
                        ),
                      ),
                      // BERT badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.80),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF9966CC).withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Color(0xFF7B5EA7), size: 13),
                            SizedBox(width: 6),
                            Text(
                              'BERT Analysis',
                              style: TextStyle(
                                  color: Color(0xFF7B5EA7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Title ──────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 2),
                  child: Text(
                    'Emotion Analysis',
                    style: TextStyle(
                        color: Color(0xFF2D1B4E),
                        fontSize: 26,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(
                    'Here\'s what AI detected from your words.',
                    style: TextStyle(
                        color: const Color(0xFF2D1B4E).withOpacity(0.55),
                        fontSize: 13),
                  ),
                ),

                const SizedBox(height: 14),

                // ── User text preview ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4B8E8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u201C\u201C',
                          style: TextStyle(
                            color: const Color(0xFF7FB883),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
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

                const SizedBox(height: 18),

                // ── 2×2 Emotion Arc Grid ───────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, _) {
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(scores.length, (i) {
                            final entry  = scores[i];
                            final config = _emotionConfig[entry.key]!;
                            final color  = config['color'] as Color;
                            final isTop  = entry.key == widget.detectedEmotion;
                            final animVal = _arcAnimations[i].value;

                            return _EmotionArcCard(
                              icon: config['icon'] as String,
                              label: config['label'] as String,
                              percentage: entry.value,
                              animatedValue: animVal,
                              arcColor: color,
                              isTop: isTop,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Dominant emotion card ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: dominantColor.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: dominantColor.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: dominantColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(dominantIcon,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 14),
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
                              const SizedBox(height: 3),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: dominantLabel,
                                      style: TextStyle(
                                          color: dominantColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(
                                      text:
                                          '  •  ${(widget.confidence * 100).toStringAsFixed(1)}% confidence',
                                      style: const TextStyle(
                                          color: Color(0xFF2D1B4E),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Select Emotion button ──────────────────────────────
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
                        elevation: 6,
                        shadowColor: const Color(0xFF9966CC).withOpacity(0.45),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Select Emotion',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
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

// ── Emotion Arc Card ─────────────────────────────────────────────────────────
class _EmotionArcCard extends StatelessWidget {
  final String icon;
  final String label;
  final double percentage;
  final double animatedValue;
  final Color arcColor;
  final bool isTop;

  const _EmotionArcCard({
    required this.icon,
    required this.label,
    required this.percentage,
    required this.animatedValue,
    required this.arcColor,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percentage * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop
              ? arcColor.withOpacity(0.35)
              : const Color(0xFFDDD0F0).withOpacity(0.6),
          width: isTop ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop
                ? arcColor.withOpacity(0.18)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular arc with emoji
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _ArcPainter(
                progress: animatedValue.clamp(0.0, 1.0),
                color: arcColor,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Emotion label
          Text(
            label,
            style: TextStyle(
              color: isTop ? arcColor : const Color(0xFF4A3A65),
              fontSize: 14,
              fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          // Percentage
          Text(
            '$pct%',
            style: const TextStyle(
              color: Color(0xFF2D1B4E),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arc CustomPainter ────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // top of circle
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
