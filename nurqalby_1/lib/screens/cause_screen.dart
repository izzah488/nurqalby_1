import 'package:flutter/material.dart';
import 'result_screen.dart';

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

  void _findVerses() {
    if (selectedCause == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cause.'),
          backgroundColor: Color(0xFF1a3a2a),
        ),
      );
      return;
    }
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
      backgroundColor: const Color(0xFF0d2016),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cause Selection',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'What is causing this feeling?',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Refining results for ',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12),
                        ),
                        TextSpan(
                          text: widget.emotion[0].toUpperCase() +
                              widget.emotion.substring(1),
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Cause list
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
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1a3a2a)
                            : const Color(0xFF142d1e),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2d5a3d),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width:  44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                      .withOpacity(0.2)
                                  : const Color(0xFF2d5a3d),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              c['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withOpacity(0.6),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['label'],
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withOpacity(0.85),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(c['subtitle'],
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Radio(
                            value:          c['value'],
                            groupValue:     selectedCause,
                            onChanged: (val) =>
                                setState(() => selectedCause = val),
                            activeColor: const Color(0xFF4CAF50),
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(
                                      WidgetState.selected)
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Find Verses button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _findVerses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Find Verses →',
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