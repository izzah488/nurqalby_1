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

  Future<void> _next() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please describe how you feel.')));
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
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFF0F1E12),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- Top bar ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A4930),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3D6645)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: Color(0xFFB8D4BB), size: 14),
                        SizedBox(width: 6),
                        Text('NurQalby',
                            style: TextStyle(
                                color: Color(0xFFB8D4BB),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  // Notification settings button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4930),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFF3D6645)),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFFB8D4BB),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- Step indicator ---
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? const Color(0xFF355E3B)
                          : const Color(0xFF2A4930),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1 of 3  •  Tell us how you feel',
                style: TextStyle(
                    color: Color(0xFFB8D4BB),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3),
              ),

              const SizedBox(height: 28),

              // --- Title ---
              const Text('🌙', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 12),
              const Text('How is your',
                  style: TextStyle(
                      color: Color(0xFFFFFDD0),
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              const Text('heart feeling?',
                  style: TextStyle(
                      color: Color(0xFF7FB883),
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Share what is on your mind — we will find the guidance you need.',
                style: TextStyle(
                    color: Color(0xFFFFFDD0),
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 28),

              // --- Text field ---
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3320),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3D6645)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF355E3B).withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: const TextStyle(
                    color: Color(0xFFFFFDD0),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. I feel anxious about my future...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFFFFDD0), fontSize: 14),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(top: 14, left: 4),
                      child: Icon(Icons.edit_note_rounded,
                          color: Color(0xFFB8D4BB), size: 22),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 42, minHeight: 42),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Analyse button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF355E3B),
                    disabledBackgroundColor: const Color(0xFF355E3B).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF355E3B).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFFDD0), strokeWidth: 2.5),
                        )
                      : const Text(
                          'Analyse Emotion →',
                          style: TextStyle(
                              color: Color(0xFFFFFDD0),
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
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

