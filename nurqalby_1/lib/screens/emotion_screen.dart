import 'package:flutter/material.dart';
import 'cause_screen.dart';
import 'notification_settings_screen.dart';

class EmotionScreen extends StatefulWidget {
  final String userText;
  final String? detectedEmotion;
  final double? confidence;

  const EmotionScreen({
    super.key,
    required this.userText,
    this.detectedEmotion,
    this.confidence,
  });

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen>
    with SingleTickerProviderStateMixin {
  String? selectedEmotion;

  late AnimationController _controller;

  final List<Map<String, dynamic>> emotions = [
    {
      'label': 'Sadness',
      'icon': '😔',
      'value': 'sadness',
      'accentColor': Color(0xFF5B8DEF),
    },
    {
      'label': 'Fear',
      'icon': '😨',
      'value': 'fear',
      'accentColor': Color(0xFF607D8B),
    },
    {
      'label': 'Anger',
      'icon': '😠',
      'value': 'anger',
      'accentColor': Color(0xFFE57373),
    },
    {
      'label': 'Joy',
      'icon': '😊',
      'value': 'joy',
      'accentColor': Color(0xFFFFC857),
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    if (widget.detectedEmotion != null) {
      final match =
          emotions.any((e) => e['value'] == widget.detectedEmotion);

      if (match) {
        selectedEmotion = widget.detectedEmotion;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> get currentEmotion {
    return emotions.firstWhere(
      (e) => e['value'] == selectedEmotion,
      orElse: () => emotions[0],
    );
  }

  void _next() {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emotion.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CauseScreen(
          userText: widget.userText,
          emotion: selectedEmotion!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        (currentEmotion['accentColor'] as Color).withOpacity(0.85);

    return Scaffold(
      body: Stack(
        children: [

          // ===== Background Image =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundemotion.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ===== Soft White Overlay =====
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.72),
            ),
          ),

          // ===== Decorative Patterns =====
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB497D6).withOpacity(0.14),
              ),
            ),
          ),

          Positioned(
            bottom: -90,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDCCEF2).withOpacity(0.18),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ===== HEADER =====
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      // ===== Top Buttons =====
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          _glassButton(
                            icon: Icons.arrow_back,
                            onTap: () =>
                                Navigator.pop(context),
                          ),

                          _glassButton(
                            icon:
                                Icons.notifications_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ===== Step Indicator =====
                      Row(
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsets.only(
                                  right: i < 2 ? 8 : 0),
                              decoration: BoxDecoration(
                                color: i <= 1
                                    ? const Color(
                                        0xFF8E6BBE)
                                    : const Color(
                                        0xFFDCCEF2),
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Step 2 of 3  •  Emotional Reflection',
                        style: TextStyle(
                          color: Color(0xFF7B5EA7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // ===== Title =====
                      const Text(
                        'Select Emotion',
                        style: TextStyle(
                          fontSize: 42,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D1B4E),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        widget.detectedEmotion != null
                            ? 'We detected your emotion — you can change it below if needed.'
                            : 'Select one emotion to continue.',
                        style: TextStyle(
                          color:
                              Colors.black.withOpacity(0.55),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),

                      // ===== BERT CARD =====
                      if (widget.detectedEmotion !=
                          null) ...[
                        const SizedBox(height: 22),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.78),
                            borderRadius:
                                BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                  0xFFDCCEF2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.04),
                                blurRadius: 18,
                                offset:
                                    const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [

                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFEDE5F8),
                                  borderRadius:
                                      BorderRadius
                                          .circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(
                                      0xFF8E6BBE),
                                  size: 20,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    const Text(
                                      'BERT detected emotion',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(
                                            0xFF2D1B4E),
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 3),

                                    Text(
                                      '${widget.detectedEmotion![0].toUpperCase()}'
                                      '${widget.detectedEmotion!.substring(1)} '
                                      '(${((widget.confidence ?? 0) * 100).toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        color: Colors
                                            .black
                                            .withOpacity(
                                                0.55),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // ===== BIG EMOJI =====
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 400),
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withOpacity(0.15),
                        accent.withOpacity(0.04),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.22),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withOpacity(0.95),
                            accent.withOpacity(0.72),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                accent.withOpacity(0.35),
                            blurRadius: 24,
                            offset:
                                const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration:
                              const Duration(
                                  milliseconds: 250),
                          child: Text(
                            currentEmotion['icon'],
                            key:
                                ValueKey(selectedEmotion),
                            style: const TextStyle(
                                fontSize: 72),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ===== Bottom Emotion Panel =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                      20, 26, 20, 24),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.92),
                    borderRadius:
                        const BorderRadius.vertical(
                      top: Radius.circular(38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      // Handle
                      Container(
                        width: 55,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFDCCEF2),
                          borderRadius:
                              BorderRadius.circular(
                                  10),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== Emotion Selector =====
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceEvenly,
                        children:
                            emotions.map((emotion) {
                          final bool isSelected =
                              selectedEmotion ==
                                  emotion['value'];

                          final Color itemColor =
                              emotion['accentColor'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEmotion =
                                    emotion['value'];
                              });
                            },
                            child:
                                AnimatedContainer(
                              duration:
                                  const Duration(
                                      milliseconds:
                                          250),
                              width: isSelected
                                  ? 74
                                  : 62,
                              height: isSelected
                                  ? 74
                                  : 62,
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: isSelected
                                    ? itemColor
                                        .withOpacity(
                                            0.18)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? itemColor
                                      : Colors
                                          .transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? itemColor
                                            .withOpacity(
                                                0.28)
                                        : Colors
                                            .black
                                            .withOpacity(
                                                0.05),
                                    blurRadius:
                                        isSelected
                                            ? 18
                                            : 10,
                                    offset:
                                        const Offset(
                                            0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  emotion['icon'],
                                  style: TextStyle(
                                    fontSize:
                                        isSelected
                                            ? 34
                                            : 28,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 26),

                      // ===== NEXT BUTTON =====
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFF8E6BBE),
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                    vertical: 18),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          30),
                            ),
                          ),
                          child: const Text(
                            'Select Cause →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDCCEF2),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6E4B9E),
        ),
      ),
    );
  }
}