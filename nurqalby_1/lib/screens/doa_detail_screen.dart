import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoaDetailScreen extends StatefulWidget {
  final String arabic;
  final String translation;
  final String prayerName;

  const DoaDetailScreen({
    super.key,
    required this.arabic,
    required this.translation,
    required this.prayerName,
  });

  @override
  State<DoaDetailScreen> createState() => _DoaDetailScreenState();
}

class _DoaDetailScreenState extends State<DoaDetailScreen> {
  bool isFavourite = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final prefs   = await SharedPreferences.getInstance();
    final saved   = prefs.getStringList('saved_items') ?? [];
    final thisKey = 'dua_${widget.arabic}';
    
    setState(() {
      isFavourite = saved.any((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
    });
  }

  Future<void> _toggleFavourite() async {
    final prefs   = await SharedPreferences.getInstance();
    final saved   = prefs.getStringList('saved_items') ?? [];
    final thisKey = 'dua_${widget.arabic}';

    setState(() {
      isFavourite = !isFavourite;
    });

    if (isFavourite) {
      // Save it
      saved.add(jsonEncode({
        'key':         thisKey,
        'arabic':      widget.arabic,
        'translation': widget.translation,
        'prayerName':  widget.prayerName,
        'type':        'dua',
      }));
    } else {
      // Remove it
      saved.removeWhere((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
    }

    await prefs.setStringList('saved_items', saved);
  }

  void _share() {
    Share.share(
      '${widget.arabic}\n\n"${widget.translation}"\n\nShared via NurQalby 🌿',
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(
      text: '${widget.arabic}\n\n${widget.translation}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:         Text('Doa copied to clipboard'),
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

            // --- Header ---
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
                  Text(
                    '${widget.prayerName[0].toUpperCase()}${widget.prayerName.substring(1)} Doa',
                    style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   17,
                        fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: _toggleFavourite, // Updated to use the new method
                    child: Icon(
                      isFavourite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isFavourite
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Doa card ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [

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
                                fontSize:   24,
                                fontWeight: FontWeight.w600,
                                height:     1.8),
                          ),
                          const SizedBox(height: 20),

                          const Divider(color: Color(0xFF2d5a3d)),
                          const SizedBox(height: 20),

                          // Translation
                          Text(
                            '"${widget.translation}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:     Colors.white.withOpacity(0.8),
                                fontSize:  15,
                                height:    1.6,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Action buttons ---
                    Row(
                      children: [

                        // Copy
                        Expanded(
                          child: GestureDetector(
                            onTap: _copy,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color:        const Color(0xFF142d1e),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF2d5a3d)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      color: Color(0xFF4CAF50),
                                      size:  22),
                                  SizedBox(height: 6),
                                  Text('Copy',
                                      style: TextStyle(
                                          color:    Colors.white,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Share
                        Expanded(
                          child: GestureDetector(
                            onTap: _share,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color:        const Color(0xFF142d1e),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF2d5a3d)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.share_rounded,
                                      color: Color(0xFF4CAF50),
                                      size:  22),
                                  SizedBox(height: 6),
                                  Text('Share',
                                      style: TextStyle(
                                          color:    Colors.white,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save / Favourite
                        Expanded(
                          child: GestureDetector(
                            onTap: _toggleFavourite, // Updated to use the new method
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: isFavourite
                                    ? const Color(0xFF1a3a2a)
                                    : const Color(0xFF142d1e),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFavourite
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF2d5a3d),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isFavourite
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: const Color(0xFF4CAF50),
                                    size:  22,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isFavourite ? 'Saved' : 'Save',
                                    style: const TextStyle(
                                        color:    Colors.white,
                                        fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}