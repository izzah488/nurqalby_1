import 'package:flutter/material.dart';
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
  bool _isLoading = false; // ← declared missing variable

  Future<void> _next() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please describe how you feel.')));
      return;
    }

    // Show loading
    setState(() => _isLoading = true);

    try {
      // Auto-classify emotion using BERT
      final result = await ApiService.classifyEmotion(text: text);
      final detectedEmotion = result['detected_emotion'] as String;
      final confidence = result['confidence'] as double;

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmotionScreen(
              userText: text,
              detectedEmotion: detectedEmotion, // ← now accepted by EmotionScreen
              confidence: confidence,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Fallback — let user pick manually
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
      backgroundColor: const Color(0xFF0d2016),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- Top bar with notification button ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a3a2a),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2d5a3d)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            color: Color(0xFF4CAF50), size: 14),
                        SizedBox(width: 6),
                        Text('NurQalby',
                            style: TextStyle(
                                color: Color(0xFF9fd4b0),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a3a2a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2d5a3d)),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF4CAF50),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text('How is your',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              const Text('heart feeling?',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Tell us what is on your mind to find guidance.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Text field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1a3a2a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2d5a3d)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. I feel anxious about my future...',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF4CAF50)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const Spacer(),

              // Next button — shows spinner while loading
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Select Emotion →',
                          style: TextStyle(
                              color: Colors.white,
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
