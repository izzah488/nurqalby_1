import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationDetailScreen extends StatefulWidget {
  final String arabic;
  final String english;
  final String title;
  final String reference;
  final String type; // 'verse' or 'dua'

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
    final prefs   = await SharedPreferences.getInstance();
    final saved   = prefs.getStringList('saved_items') ?? [];
    
    // Made the key dynamic based on whether it's a verse or a dua
    final thisKey = '${widget.type}_${widget.arabic}';
    
    setState(() {
      isSaved = saved.any((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
    });
  }

  Future<void> _toggleSave() async {
    final prefs   = await SharedPreferences.getInstance();
    final saved   = prefs.getStringList('saved_items') ?? [];
    final thisKey = '${widget.type}_${widget.arabic}';

    if (isSaved) {
      saved.removeWhere((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
      setState(() => isSaved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Removed from saved'),
          backgroundColor: Color(0xFF1a3a2a),
          duration:        Duration(seconds: 2),
        ),
      );
    } else {
      saved.add(jsonEncode({
        'key':       thisKey,
        'type':      widget.type,        // Uses dynamic type
        'title':     widget.title,       // Fixed: was widget.prayerName
        'arabic':    widget.arabic,
        'english':   widget.english,     // Fixed: was widget.translation
        'reference': widget.reference,   // Fixed: was empty
      }));
      setState(() => isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Saved successfully'),
          backgroundColor: Color(0xFF1a3a2a),
          duration:        Duration(seconds: 2),
        ),
      );
    }
    await prefs.setStringList('saved_items', saved);
  }

  void _share() {
    Share.share(
      '${widget.arabic}\n\n"${widget.english}"\n\n— ${widget.reference}\n\nShared via NurQalby 🌿',
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(
      text: '${widget.arabic}\n\n${widget.english}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:         Text('Copied to clipboard'),
        backgroundColor: Color(0xFF1a3a2a),
        duration:        Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d2016),
      body: SafeArea(
        child: Column(
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF1a3a2a),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.type == 'verse' ? '📖 Verse' : '🤲 Dua',
                      style: const TextStyle(
                          color:    Color(0xFF9fd4b0),
                          fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSave,
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isSaved
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [

                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:      Colors.white.withOpacity(0.7),
                          fontSize:   13,
                          fontStyle:  FontStyle.italic),
                    ),
                    const SizedBox(height: 20),

                    // Main card
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color:        const Color(0xFF142d1e),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF2d5a3d)),
                      ),
                      child: Column(
                        children: [

                          // Arabic
                          Text(
                            widget.arabic,
                            textAlign:     TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   22,
                                fontWeight: FontWeight.w600,
                                height:     1.8),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF2d5a3d)),
                          const SizedBox(height: 20),

                          // English
                          Text(
                            '"${widget.english}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:     Colors.white.withOpacity(0.85),
                                fontSize:  15,
                                height:    1.7,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 16),

                          // Reference
                          Text(
                            '— ${widget.reference}',
                            style: TextStyle(
                                color:    Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        _ActionBtn(
                          icon:  Icons.copy_rounded,
                          label: 'Copy',
                          onTap: _copy,
                        ),
                        const SizedBox(width: 12),
                        _ActionBtn(
                          icon:  Icons.share_rounded,
                          label: 'Share',
                          onTap: _share,
                        ),
                        const SizedBox(width: 12),
                        _ActionBtn(
                          icon:  isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          label: isSaved ? 'Saved' : 'Save',
                          onTap:       _toggleSave,
                          isActive:    isSaved,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final bool     isActive;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1a3a2a)
                : const Color(0xFF142d1e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF2d5a3d),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}