import 'package:flutter/material.dart';
import 'result_screen.dart';
import 'notification_settings_screen.dart'; // Ensure you have this file created

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();

  String? selectedEmotion;
  String? selectedCause;

  final List<Map<String, String>> emotions = [
    {'label': '😔 Sadness', 'value': 'sadness'},
    {'label': '😨 Fear',    'value': 'fear'},
    {'label': '😠 Anger',   'value': 'anger'},
    {'label': '😊 Joy',     'value': 'joy'},
  ];

  final List<Map<String, String>> causes = [
    {'label': '🤲 Faith / Spiritual State',  'value': 'Faith / Spiritual State'},
    {'label': '🌊 Life Trials / Hardship',   'value': 'Life Trials / Hardship'},
    {'label': '👥 Relationships / People',   'value': 'Relationships / People'},
  ];

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnack('Please describe how you feel.');
      return;
    }
    if (selectedEmotion == null) {
      _showSnack('Please select an emotion.');
      return;
    }
    if (selectedCause == null) {
      _showSnack('Please select a cause.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          userText: text,
          emotion:  selectedEmotion!,
          cause:    selectedCause!,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- Header ---
              Container(
                width: double.infinity,
                color: const Color(0xFF1a3a2a),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السلام عليكم',
                            style: TextStyle(color: Color(0xFF9fd4b0), fontSize: 13)),
                        SizedBox(height: 4),
                        Text('How are you feeling?',
                            style: TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    // Inside the header Container, add this at the end of the Row
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- Free text ---
                    const Text('TELL US WHAT\'S ON YOUR MIND',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. I feel lost and my family doesn\'t understand me...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF1a3a2a), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Emotion chips ---
                    const Text('SELECT YOUR EMOTION',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emotions.map((e) {
                        final isSelected = selectedEmotion == e['value'];
                        return GestureDetector(
                          onTap: () => setState(() => selectedEmotion = e['value']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1a3a2a)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1a3a2a)
                                    : const Color(0xFFDDDDDD),
                              ),
                            ),
                            child: Text(e['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.black87,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // --- Cause buttons ---
                    const Text('SELECT THE CAUSE',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...causes.map((c) {
                      final isSelected = selectedCause == c['value'];
                      return GestureDetector(
                        onTap: () => setState(() => selectedCause = c['value']),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1a3a2a)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1a3a2a)
                                  : const Color(0xFFDDDDDD),
                            ),
                          ),
                          child: Text(c['label']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                              )),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // --- Submit button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3a2a),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Find My Verse →',
                            style: TextStyle(fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}