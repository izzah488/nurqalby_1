import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String arabic;
  final String english;
  final String title;
  final String reference;
  final String type;

  const NotificationDetailScreen({
    super.key,
    required this.arabic,
    required this.english,
    required this.title,
    required this.reference,
    required this.type,
  });

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends State<NotificationDetailScreen> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final key = '${widget.type}_${widget.arabic}';

    setState(() {
      isSaved = saved.any((s) {
        final map = jsonDecode(s);
        return map['key'] == key;
      });
    });
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final key = '${widget.type}_${widget.arabic}';

    setState(() => isSaved = !isSaved);

    if (isSaved) {
      saved.add(jsonEncode({
        'key': key,
        'type': widget.type,
        'title': widget.title,
        'arabic': widget.arabic,
        'english': widget.english,
        'reference': widget.reference,
      }));
    } else {
      saved.removeWhere((s) {
        final map = jsonDecode(s);
        return map['key'] == key;
      });
    }

    await prefs.setStringList('saved_items', saved);
  }

  void _share() {
    Share.share(
      '${widget.arabic}\n\n"${widget.english}"\n\n— ${widget.reference}\n\nShared via NurQalby 🌿',
    );
  }

  void _copy() {
    Clipboard.setData(
      ClipboardData(text: '${widget.arabic}\n\n${widget.english}'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Color(0xFFEDE5F8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [

          // 🌿 BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgdetail.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🌿 SOFT OVERLAY (for readability)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.45),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ───────── HEADER ─────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      // Back
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE5F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFD4B8E8)),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF2D1B4E),
                          ),
                        ),
                      ),

                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE5F8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFD4B8E8)),
                        ),
                        child: Text(
                          widget.type == 'verse'
                              ? '📖 Verse'
                              : '🤲 Doa',
                          style: const TextStyle(
                            color: Color(0xFF7B5EA7),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Save button
                      GestureDetector(
                        onTap: _toggleSave,
                        child: Icon(
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isSaved
                              ? const Color(0xFF7FB883)
                              : const Color(0xFF2D1B4E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ───────── CONTENT ─────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [

                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.6),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ───────── DOA CARD (UPDATED) ─────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [

                              // 🌿 DOA CARD BACKGROUND IMAGE (FIXED)
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/dua1.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // 🌿 GLASS OVERLAY
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withOpacity(0.49),
                                ),
                              ),

                              // 🌿 CONTENT
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [

                                    // Arabic
                                    Text(
                                      widget.arabic,
                                      textAlign: TextAlign.center,
                                      textDirection:
                                          TextDirection.rtl,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w600,
                                        height: 1.8,
                                        color: Color.fromARGB(255, 7, 0, 20),
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    const Divider(
                                        color: Color(0xFFD4B8E8)),
                                    const SizedBox(height: 20),

                                    // Translation
                                    Text(
                                      '"${widget.english}"',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        fontStyle: FontStyle.italic,
                                        color: const Color.fromARGB(255, 0, 0, 0)
                                            .withOpacity(0.85),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Reference
                                    Text(
                                      '— ${widget.reference}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF2D1B4E)
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ───────── ACTION BUTTONS ─────────
                        Row(
                          children: [
                            _action(Icons.copy, "Copy", _copy),
                            const SizedBox(width: 10),
                            _action(Icons.share, "Share", _share),
                            const SizedBox(width: 10),
                            _action(
                              isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              isSaved ? "Saved" : "Save",
                              _toggleSave,
                              highlight: isSaved,
                            ),
                          ],
                        ),
                      ],
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

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {bool highlight = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFF9966CC).withOpacity(0.15)
                : const Color(0xFFEDE5F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight
                  ? const Color(0xFF9966CC)
                  : const Color(0xFFD4B8E8),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF7FB883), size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D1B4E))),
            ],
          ),
        ),
      ),
    );
  }
}
