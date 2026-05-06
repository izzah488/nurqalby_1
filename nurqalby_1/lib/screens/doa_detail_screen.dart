import 'dart:convert';
import 'dart:ui'; // IMPORTANT for blur
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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final thisKey = 'dua_${widget.arabic}';

    setState(() {
      isFavourite = saved.any((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
    });
  }

  Future<void> _toggleFavourite() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final thisKey = 'dua_${widget.arabic}';

    setState(() => isFavourite = !isFavourite);

    if (isFavourite) {
      saved.add(jsonEncode({
        'key': thisKey,
        'type': 'dua',
        'title': widget.prayerName,
        'arabic': widget.arabic,
        'english': widget.translation,
        'reference': '',
      }));
    } else {
      saved.removeWhere((s) {
        final map = jsonDecode(s);
        return map['key'] == thisKey;
      });
    }

    await prefs.setStringList('saved_items', saved);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isFavourite ? 'Saved successfully' : 'Removed from saved'),
        backgroundColor: const Color(0xFFEDE5F8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share() {
    Share.share(
      '${widget.arabic}\n\n"${widget.translation}"\n\nShared via NurQalby 🌿',
    );
  }

  void _copy() {
    Clipboard.setData(
      ClipboardData(
        text: '${widget.arabic}\n\n${widget.translation}',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doa copied to clipboard'),
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

          // 🌿 SOFT OVERLAY (IMPORTANT FOR READABILITY)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.85),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // ───── HEADER ─────
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
                          child: const Icon(Icons.arrow_back,
                              color: Color(0xFF2D1B4E), size: 20),
                        ),
                      ),

                      // Title
                      Text(
                        '${widget.prayerName[0].toUpperCase()}${widget.prayerName.substring(1)} Doa',
                        style: const TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Bookmark
                      GestureDetector(
                        onTap: _toggleFavourite,
                        child: Icon(
                          isFavourite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: isFavourite
                              ? const Color(0xFF7FB883)
                              : const Color(0xFF2D1B4E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ───── CONTENT ─────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [

                        // Label
                        Text(
                          "Recommended Doa",
                          style: TextStyle(
                            color: const Color(0xFF2D1B4E)
                                .withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🌿 DOA CARD WITH IMAGE + BLUR
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [

                              // Image
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/verse1.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Blur
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    color: Colors.white
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ),

                              // Content
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(24),
                                child: Column(
                                  children: [

                                    // Arabic
                                    Text(
                                      widget.arabic,
                                      textAlign: TextAlign.center,
                                      textDirection:
                                          TextDirection.rtl,
                                      style: const TextStyle(
                                        color: Color(0xFF2D1B4E),
                                        fontSize: 26,
                                        fontWeight:
                                            FontWeight.w600,
                                        height: 1.8,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6,
                                            color: Colors.black12,
                                          )
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    const Divider(
                                        color: Color(0xFFD4B8E8)),
                                    const SizedBox(height: 20),

                                    // Translation
                                    Text(
                                      '"${widget.translation}"',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(
                                                0xFF2D1B4E)
                                            .withOpacity(0.85),
                                        fontSize: 15,
                                        height: 1.6,
                                        fontStyle:
                                            FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ───── ACTION BUTTONS ─────
                        Row(
                          children: [

                            _buildAction(
                                icon: Icons.copy,
                                label: "Copy",
                                onTap: _copy),

                            const SizedBox(width: 10),

                            _buildAction(
                                icon: Icons.share,
                                label: "Share",
                                onTap: _share),

                            const SizedBox(width: 10),

                            _buildAction(
                              icon: isFavourite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              label: isFavourite
                                  ? "Saved"
                                  : "Save",
                              onTap: _toggleFavourite,
                              highlight: isFavourite,
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

  // 🔹 Reusable button
  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
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
              Icon(icon,
                  color: const Color(0xFF7FB883), size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF2D1B4E),
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
