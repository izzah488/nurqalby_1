import 'package:flutter/material.dart';
import 'emotion_analysis_screen.dart';
import 'emotion_screen.dart';
import 'notification_settings_screen.dart';
import '../services/api_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  // ===== Color Palette =====
  static const Color kBackground = Color(0xFFF8F6FC);
  static const Color kCard = Color(0xFFF1EAFB);
  static const Color kPrimary = Color(0xFF8E6BBE);
  static const Color kPrimaryDark = Color(0xFF6E4B9E);
  static const Color kAccent = Color(0xFFA8CFA8);
  static const Color kTextDark = Color(0xFF2D1B4E);
  static const Color kBorder = Color(0xFFDCCEF2);

  Future<void> _next() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe how you feel.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.classifyEmotion(text: text);

      final detectedEmotion = result['detected_emotion'] as String;
      final confidence = (result['confidence'] as num).toDouble();
      final allScores = result['all_scores'] as Map<String, double>?;

      if (mounted) {
        setState(() => _isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmotionAnalysisScreen(
              userText: text,
              detectedEmotion: detectedEmotion,
              confidence: confidence,
              allScores: allScores,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmotionScreen(userText: text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ===== Background Image Pattern =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundinput.jpg', // Ensure this path matches your asset folder
              fit: BoxFit.cover,
            ),
          ),

          // ===== Subtle Overlay for Readability =====
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.3),
            ),
          ),

          // ===== Decorative Circle Top Right =====
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ===== Decorative Small Pattern Top Left =====
          Positioned(
            top: 120,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                border: Border.all(
                  color: kPrimary.withOpacity(0.1),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // ===== Decorative Circle Bottom Left =====
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: kAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Top Bar =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ===== UiTM + App Box =====
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ===== UiTM Logo =====
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/uitm_logo.png',
                                width: 70,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.school, color: kPrimary),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // ===== App Name =====
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'NurQalby',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'UiTM FYP Project',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF7A6A92),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ===== Notification Button =====
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: kPrimaryDark,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // ===== Step Indicator =====
                  Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 5,
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: i == 0 ? kPrimary : kPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Step 1 of 3  •  Emotional Reflection',
                    style: TextStyle(
                      color: kPrimaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // ===== Emoji =====
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🌙',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===== Heading =====
                  const Text(
                    'How is your',
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),

                  const Text(
                    'heart feeling?',
                    style: TextStyle(
                      color: kPrimary, // Changed to Primary for better contrast on background
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Share what is on your mind — we will help guide you through emotional and spiritual reflection.',
                    style: TextStyle(
                      color: Color(0xFF4A3A65),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ===== Input Card =====
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 15,
                        height: 1.8,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText:
                            'Example: I feel anxious about my future and overwhelmed with my studies...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8D82A2),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(top: 10, left: 16),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: kPrimary,
                            size: 24,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 50,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(16, 18, 20, 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // ===== Analyse Button =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          kPrimary,
                          Color(0xFFB497D6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Analyse Emotion',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}