import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ShareScreen extends StatefulWidget {
  final Map<String, dynamic> verse;

  const ShareScreen({super.key, required this.verse});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final GlobalKey _cardKey = GlobalKey();

  // Share as plain text
  void _shareText() {
    final surah   = widget.verse['surah'];
    final ayah    = widget.verse['ayah'];
    final arabic  = widget.verse['arabic_text'] ?? '';
    final english = widget.verse['verse_text']  ?? '';

    final text = '''
$arabic

"$english"

— Surah $surah, Ayah $ayah

Shared via NurQalby 🌿
''';

    Share.share(text);
  }

  // Share to WhatsApp specifically
  void _shareWhatsApp() {
    final surah   = widget.verse['surah'];
    final ayah    = widget.verse['ayah'];
    final arabic  = widget.verse['arabic_text'] ?? '';
    final english = widget.verse['verse_text']  ?? '';

    final text = '''
$arabic

"$english"

— Surah $surah, Ayah $ayah

Shared via NurQalby 🌿
''';

    Share.shareWithResult(text);
  }

  // Copy text to clipboard
  void _copyText() {
    final surah   = widget.verse['surah'];
    final ayah    = widget.verse['ayah'];
    final arabic  = widget.verse['arabic_text'] ?? '';
    final english = widget.verse['verse_text']  ?? '';

    final text = '$arabic\n\n"$english"\n\n— Surah $surah, Ayah $ayah';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:         Text('Verse copied to clipboard'),
        backgroundColor: Color(0xFF1a3a2a),
        duration:        Duration(seconds: 2),
      ),
    );
  }

  // Save card as image and share
  Future<void> _saveImage() async {
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name:     'nurqalby_verse.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Shared via NurQalby 🌿',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah   = widget.verse['surah'];
    final ayah    = widget.verse['ayah'];
    final arabic  = widget.verse['arabic_text'] ?? '';
    final english = widget.verse['verse_text']  ?? '';

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
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 24),
                  ),
                  const Text('Share Verse',
                      style: TextStyle(
                          color:      Colors.white,
                          fontSize:   17,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _shareText,
                    child: const Text('Done',
                        style: TextStyle(
                            color:      Color(0xFF4CAF50),
                            fontSize:   15,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verse card — this is what gets saved as image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF0d2016),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2d5a3d), width: 1),
                  ),
                  child: Column(
                    children: [
                      // Quote icon
                      const Text('❝',
                          style: TextStyle(
                              color:    Color(0xFF4CAF50),
                              fontSize: 36)),
                      const SizedBox(height: 16),

                      // Arabic
                      Text(
                        arabic,
                        textAlign:       TextAlign.center,
                        textDirection:   TextDirection.rtl,
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w600,
                            height:     1.8),
                      ),
                      const SizedBox(height: 16),

                      // English
                      Text(
                        '"$english"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:    Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            height:   1.6,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),

                      // Surah info
                      Text(
                        'SURAH $surah • AYAH $ayah',
                        style: const TextStyle(
                            color:          Color(0xFF4CAF50),
                            fontSize:       11,
                            fontWeight:     FontWeight.w600,
                            letterSpacing:  1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shared via NurQalby 🌿',
                        style: TextStyle(
                            color:    Colors.white.withOpacity(0.3),
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share to label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Share to',
                    style: TextStyle(
                        color:      Colors.white.withOpacity(0.6),
                        fontSize:   13,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 16),

            // Social buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SocialButton(
                    icon:    Icons.camera_alt_rounded,
                    label:   'Stories',
                    color:   const Color(0xFFE1306C),
                    onTap:   _saveImage,
                  ),
                  _SocialButton(
                    icon:    Icons.chat_rounded,
                    label:   'WhatsApp',
                    color:   const Color(0xFF25D366),
                    onTap:   _shareWhatsApp,
                  ),
                  _SocialButton(
                    icon:    Icons.facebook_rounded,
                    label:   'Facebook',
                    color:   const Color(0xFF1877F2),
                    onTap:   _shareText,
                  ),
                  _SocialButton(
                    icon:    Icons.close_rounded,
                    label:   'X',
                    color:   Colors.white,
                    onTap:   _shareText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Divider(color: Colors.white.withOpacity(0.1)),

            // Copy text button
            _ActionButton(
              icon:    Icons.copy_rounded,
              label:   'Copy Text',
              onTap:   _copyText,
            ),

            Divider(color: Colors.white.withOpacity(0.1)),

            // Save image button
            _ActionButton(
              icon:    Icons.download_rounded,
              label:   'Save Image',
              onTap:   _saveImage,
            ),

            Divider(color: Colors.white.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width:  56,
            height: 56,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.15),
              shape:        BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color:    Colors.white.withOpacity(0.7),
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color:    Colors.white.withOpacity(0.8),
                    fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}