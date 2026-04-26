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
      'label':    'Faith / Spiritual State',
      'subtitle': 'Doubt, distance, or seeking purpose',
      'icon':     Icons.mosque_rounded,
      'value':    'Faith / Spiritual State',
    },
    {
      'label':    'Life Trials / Hardship',
      'subtitle': 'Difficulties, struggles, or hardship',
      'icon':     Icons.waves_rounded,
      'value':    'Life Trials / Hardship',
    },
    {
      'label':    'Relationships / People',
      'subtitle': 'Conflict, disconnect, or worry',
      'icon':     Icons.people_rounded,
      'value':    'Relationships / People',
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

    // Save mood log now that both emotion AND cause are known
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
          emotion:  widget.emotion,
          cause:    selectedCause!,
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

                      // Notification button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        ),
                        child: Container(
                          width:  42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:        const Color(0xFFEDE5F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4B8E8)),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF7B5EA7),
                            size:  22,
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
                          color: const Color(0xFF9966CC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Step 3 of 3  •  Select the cause',
                    style: TextStyle(
                        color: Color(0xFF7B5EA7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 16),
                  const Text('Cause Selection',
                      style: TextStyle(
                          color:      Color(0xFF2D1B4E),
                          fontSize:   22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'What is causing this feeling?',
                    style: TextStyle(
                        color: Color(0xFF2D1B4E),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Refining results for ',
                          style: TextStyle(
                              color:    const Color(0xFF2D1B4E).withOpacity(0.5),
                              fontSize: 12),
                        ),
                        TextSpan(
                          text: widget.emotion[0].toUpperCase() +
                              widget.emotion.substring(1),
                          style: const TextStyle(
                              color:      Color(0xFF9966CC),
                              fontSize:   12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Cause list ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: causes.length,
                itemBuilder: (context, index) {
                  final c          = causes[index];
                  final isSelected = selectedCause == c['value'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedCause = c['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:   const EdgeInsets.only(bottom: 12),
                      padding:  const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEDE5F8)
                            : const Color(0xFFEDE5F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF9966CC)
                              : const Color(0xFFD4B8E8),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF9966CC).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width:  48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF9966CC)
                                  : const Color(0xFFEDE5F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              c['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFF2D1B4E)
                                  : const Color(0xFF7B5EA7),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['label'],
                                    style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF2D1B4E)
                                            : const Color(0xFF2D1B4E).withOpacity(0.85),
                                        fontSize:   14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(c['subtitle'],
                                    style: TextStyle(
                                        color: const Color(0xFF2D1B4E).withOpacity(0.45),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Radio(
                            value:      c['value'],
                            groupValue: selectedCause,
                            onChanged:  (val) =>
                                setState(() => selectedCause = val),
                            activeColor: const Color(0xFF9966CC),
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Color(0xFF9966CC)
                                  : const Color(0xFF2D1B4E).withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Find Verses button ---
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
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF9966CC).withOpacity(0.4),
                  ),
                  child: const Text('Find Verses →',
                      style: TextStyle(
                          color:      Color(0xFF2D1B4E),
                          fontSize:   16,
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
