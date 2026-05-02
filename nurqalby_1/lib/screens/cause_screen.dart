import 'package:flutter/material.dart';
import 'result_screen.dart';
import 'notification_settings_screen.dart';
import 'package:nurqalby_1/services/mood_database.dart';

class CauseScreen extends StatefulWidget {
  final String userText;
  final String emotion;

  const CauseScreen({
    super.key,
    required this.userText,
    required this.emotion,
  });

  @override
  State<CauseScreen> createState() => _CauseScreenState();
}

class _CauseScreenState extends State<CauseScreen> {
  String? selectedCause;

  final List<Map<String, dynamic>> causes = [
    {
      'label': 'Faith / Spiritual State',
      'subtitle': 'Doubt, distance, or seeking purpose',
      'icon': Icons.mosque_rounded,
      'value': 'Faith / Spiritual State',
      'image': 'assets/images/faith.png',
    },
    {
      'label': 'Life Trials / Hardship',
      'subtitle': 'Difficulties, struggles, or hardship',
      'icon': Icons.waves_rounded,
      'value': 'Life Trials / Hardship',
      'image': 'assets/images/life.png',
    },
    {
      'label': 'Relationships / People',
      'subtitle': 'Conflict, disconnect, or worry',
      'icon': Icons.people_rounded,
      'value': 'Relationships / People',
      'image': 'assets/images/people.png',
    },
  ];

  Future<void> _findVerses() async {
    if (selectedCause == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a cause.',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFEDE5F8),
        ),
      );
      return;
    }

    await MoodDatabase.instance.insertMood(
      widget.emotion,
      selectedCause!,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          userText: widget.userText,
          emotion: widget.emotion,
          cause: selectedCause!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = causes.firstWhere(
      (c) => c['value'] == selectedCause,
      orElse: () => causes[0],
    );

    return Scaffold(
      body: Stack(
        children: [
          /// 🌄 BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgcause.jpg',
              fit: BoxFit.cover,
            ),
          ),

          /// 🌫️ GRADIENT OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔝 HEADER (MATCHED WITH EMOTION SCREEN)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Glass Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _glassButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          _glassButton(
                            icon: Icons.notifications_outlined,
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

                      /// Progress Bar
                      Row(
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E6BBE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Step 3 of 3  •  Select the cause',
                        style: TextStyle(
                          color: Color(0xFF7B5EA7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Cause Selection',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D1B4E),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'What is causing this feeling?',
                        style: TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// Emotion Text
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Refining results for ',
                              style: TextStyle(
                                color: const Color(0xFF2D1B4E)
                                    .withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: widget.emotion[0].toUpperCase() +
                                  widget.emotion.substring(1),
                              style: const TextStyle(
                                color: Color(0xFF9966CC),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🖼️ IMAGE
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: ValueKey(selected['image']),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.asset(
                            selected['image'],
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// 🔘 CAUSE CARDS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: causes.map((c) {
                      final isSelected = selectedCause == c['value'];

                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedCause = c['value']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF9966CC)
                                  : const Color(0xFFE0D6F5),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF9966CC)
                                      : const Color(0xFFEDE5F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  c['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF7B5EA7),
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['label'],
                                      style: const TextStyle(
                                        color: Color(0xFF2D1B4E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['subtitle'],
                                      style: TextStyle(
                                        color: const Color(0xFF2D1B4E)
                                            .withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                /// 🔘 BUTTON
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _findVerses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9966CC),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                        shadowColor:
                            const Color(0xFF9966CC).withOpacity(0.4),
                      ),
                      child: const Text(
                        'Find Verses →',
                        style: TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  /// 🌟 Glass Button (same as EmotionScreen)
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDCCEF2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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