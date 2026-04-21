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

class _EmotionScreenState extends State<EmotionScreen> {
  String? selectedEmotion;

  final List<Map<String, dynamic>> emotions = [
    {'label': 'Sadness', 'icon': '😔', 'value': 'sadness'},
    {'label': 'Fear',    'icon': '😨', 'value': 'fear'},
    {'label': 'Anger',   'icon': '😠', 'value': 'anger'},
    {'label': 'Joy',     'icon': '😊', 'value': 'joy'},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select the BERT-detected emotion if provided and valid
    if (widget.detectedEmotion != null) {
      final match = emotions.any((e) => e['value'] == widget.detectedEmotion);
      if (match) selectedEmotion = widget.detectedEmotion;
    }
  }

  void _next() {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emotion.'),
          backgroundColor: Color(0xFF1a3a2a),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0d2016),
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
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
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

                  const SizedBox(height: 20),
                  const Text('Select Emotion',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    widget.detectedEmotion != null
                        ? 'We detected your emotion — feel free to change it.'
                        : 'Select one emotion to find guidance.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),

                  // BERT confidence badge
                  if (widget.detectedEmotion != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a3a2a),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF4CAF50), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'BERT detected: '
                              '${widget.detectedEmotion![0].toUpperCase()}'
                              '${widget.detectedEmotion!.substring(1)}'
                              ' (${((widget.confidence ?? 0) * 100).toStringAsFixed(0)}% confidence)',
                              style: const TextStyle(
                                  color: Color(0xFF9fd4b0), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can change it below if needed.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 11),
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
                    childAspectRatio: 1.2,
                  ),
                  itemCount: emotions.length,
                  itemBuilder: (context, index) {
                    final e = emotions[index];
                    final isSelected = selectedEmotion == e['value'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedEmotion = e['value']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1a3a2a)
                              : const Color(0xFF142d1e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2d5a3d),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e['icon'],
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(e['label'],
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              const Text('Selected',
                                  style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 11)),
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
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Select Cause →',
                      style: TextStyle(
                          color: Colors.white,
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
