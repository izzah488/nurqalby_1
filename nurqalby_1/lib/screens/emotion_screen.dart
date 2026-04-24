import 'package:flutter/material.dart';
import 'cause_screen.dart';
import 'notification_settings_screen.dart';
import 'package:nurqalby_1/services/mood_database.dart';

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

class _EmotionScreenState extends State<EmotionScreen> {
  String? selectedEmotion;

  final List<Map<String, dynamic>> emotions = [
    {'label': 'Sadness', 'icon': '😔', 'value': 'sadness', 'accentColor': Color(0xFF2979B8)},
    {'label': 'Fear',    'icon': '😨', 'value': 'fear',    'accentColor': Color(0xFF455A64)},
    {'label': 'Anger',   'icon': '😠', 'value': 'anger',   'accentColor': Color(0xFFD32F2F)},
    {'label': 'Joy',     'icon': '😊', 'value': 'joy',     'accentColor': Color(0xFFE8A020)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.detectedEmotion != null) {
      final match = emotions.any((e) => e['value'] == widget.detectedEmotion);
      if (match) selectedEmotion = widget.detectedEmotion;
    }
  }

  Future<void> _next() async {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emotion.'),
          backgroundColor: Color(0xFFEDE5F8),
        ),
      );
      return;
    }

    await MoodDatabase.instance.insertMood(
      emotion: selectedEmotion!,
    );

    if (!mounted) return;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- Header ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Back + notification row
                  Row(
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
                            color: const Color(0xFFEDE5F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4B8E8)),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF7B5EA7),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Step indicator
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i <= 1
                              ? const Color(0xFF9966CC)
                              : const Color(0xFFEDE5F8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Step 2 of 3  •  Confirm your emotion',
                    style: TextStyle(
                        color: Color(0xFF7B5EA7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 16),
                  const Text('Select Emotion',
                      style: TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    widget.detectedEmotion != null
                        ? 'We detected your emotion — feel free to change it.'
                        : 'Select one emotion to find guidance.',
                    style: const TextStyle(
                        color: Color(0xFF2D1B4E), fontSize: 13),
                  ),

                  // BERT confidence badge
                  if (widget.detectedEmotion != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF9966CC).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF7B5EA7), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'BERT detected: '
                              '${widget.detectedEmotion![0].toUpperCase()}'
                              '${widget.detectedEmotion!.substring(1)}'
                              ' (${((widget.confidence ?? 0) * 100).toStringAsFixed(0)}% confidence)',
                              style: const TextStyle(
                                  color: Color(0xFF7B5EA7), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You can change it below if needed.',
                      style: TextStyle(
                          color: Color(0xFF2D1B4E), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            // --- Emotion grid ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: emotions.length,
                  itemBuilder: (context, index) {
                    final e = emotions[index];
                    final isSelected = selectedEmotion == e['value'];
                    final accent = e['accentColor'] as Color;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedEmotion = e['value']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withOpacity(0.12)
                              : const Color(0xFFEDE5F8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? accent.withOpacity(0.65)
                                : const Color(0xFFD4B8E8),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: accent.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e['icon'],
                                style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 10),
                            Text(e['label'],
                                style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF2D1B4E)
                                        : const Color(0xFF2D1B4E).withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Selected ✓',
                                    style: TextStyle(
                                        color: accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- Next button ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966CC),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF9966CC).withOpacity(0.4),
                  ),
                  child: const Text('Select Cause →',
                      style: TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
