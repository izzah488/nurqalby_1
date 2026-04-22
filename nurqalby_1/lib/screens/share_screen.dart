import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

class ShareScreen extends StatefulWidget {
  final Map<String, dynamic> verse;
  const ShareScreen({super.key, required this.verse});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;

  void _shareText() {
    final s  = widget.verse['surah'];
    final a  = widget.verse['ayah'];
    final ar = widget.verse['arabic_text'] ?? '';
    final en = widget.verse['verse_text']  ?? '';
    Share.share('$ar\n\n"$en"\n\n— Surah $s, Ayah $a\n\nShared via NurQalby 🌿');
  }

  void _copyText() {
    final s  = widget.verse['surah'];
    final a  = widget.verse['ayah'];
    final ar = widget.verse['arabic_text'] ?? '';
    final en = widget.verse['verse_text']  ?? '';
    Clipboard.setData(ClipboardData(
        text: '$ar\n\n"$en"\n\n— Surah $s, Ayah $a'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:         Text('Verse copied to clipboard'),
        backgroundColor: Color(0xFF2A4930),
        duration:        Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAndShareImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) { _shareText(); return; }
      final image    = await boundary.toImage(pixelRatio: 3.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { _shareText(); return; }
      final xFile = XFile.fromData(
        byteData.buffer.asUint8List(),
        mimeType: 'image/png',
        name:     'nurqalby_verse.png',
      );
      await Share.shareXFiles([xFile], text: 'Shared via NurQalby 🌿');
    } catch (_) {
      _shareText();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah  = widget.verse['surah'];
    final ayah   = widget.verse['ayah'];
    final arabic = widget.verse['arabic_text'] ?? '';
    final eng    = widget.verse['verse_text']  ?? '';

    final totalChars = arabic.length + eng.length;

    final double arabicFontSize = totalChars > 400
        ? 14.0 : totalChars > 250 ? 17.0 : totalChars > 150 ? 19.0 : 22.0;
    final double engFontSize = totalChars > 400
        ? 11.0 : totalChars > 250 ? 13.0 : totalChars > 150 ? 14.0 : 15.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E12),
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
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color:        const Color(0xFF2A4930),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3D6645)),
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFFFFFDD0), size: 20),
                    ),
                  ),
                  const Text('Share Verse',
                      style: TextStyle(
                          color:      Color(0xFFFFFDD0),
                          fontSize:   17,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _shareText,
                    child: const Text('Done',
                        style: TextStyle(
                            color:      Color(0xFF7FB883),
                            fontSize:   15,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [

                    // Shareable card
                    RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F1E12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // App badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book_rounded,
                                    color: Color(0xFF7FB883), size: 13),
                                const SizedBox(width: 5),
                                Text('NurQalby',
                                    style: TextStyle(
                                        color:         const Color(0xFFFFFDD0).withOpacity(0.35),
                                        fontSize:      10,
                                        letterSpacing: 1.2,
                                        fontWeight:    FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            const Text('❝',
                                style: TextStyle(
                                    color:    Color(0xFF7FB883),
                                    fontSize: 36)),
                            const SizedBox(height: 16),

                            // Arabic
                            Text(
                              arabic,
                              textAlign:     TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                  color:      const Color(0xFFFFFDD0),
                                  fontSize:   arabicFontSize,
                                  fontWeight: FontWeight.w700,
                                  height:     1.85),
                            ),
                            const SizedBox(height: 18),

                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  Color(0xFF355E3B),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // English
                            Text(
                              '"$eng"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:     const Color(0xFFFFFDD0).withOpacity(0.82),
                                  fontSize:  engFontSize,
                                  height:    1.65,
                                  fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 18),

                            // Surah pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF7FB883).withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'SURAH $surah  •  AYAH $ayah',
                                style: const TextStyle(
                                    color:         Color(0xFF7FB883),
                                    fontSize:      10,
                                    fontWeight:    FontWeight.w700,
                                    letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Watermark
                            Text(
                              'nurqalby.app',
                              style: TextStyle(
                                  color:         const Color(0xFFFFFDD0).withOpacity(0.18),
                                  fontSize:      9,
                                  letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Share to label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Share to',
                          style: TextStyle(
                              color:      const Color(0xFFFFFDD0).withOpacity(0.6),
                              fontSize:   13,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SocialBtn(
                            icon:  Icons.camera_alt_rounded,
                            label: 'Stories',
                            color: const Color(0xFFE1306C),
                            onTap: _saveAndShareImage),
                        _SocialBtn(
                            icon:  Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: _shareText),
                        _SocialBtn(
                            icon:  Icons.facebook_rounded,
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            onTap: _shareText),
                        _SocialBtn(
                            icon:  Icons.share_rounded,
                            label: 'More',
                            color: const Color(0xFFFFFDD0),
                            onTap: _shareText),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Divider(color: const Color(0xFFFFFDD0).withOpacity(0.1)),
                    _ActionBtn(
                        icon:  Icons.copy_rounded,
                        label: 'Copy Text',
                        onTap: _copyText),
                    Divider(color: const Color(0xFFFFFDD0).withOpacity(0.1)),
                    _ActionBtn(
                        icon: _isSaving
                            ? Icons.hourglass_bottom_rounded
                            : Icons.download_rounded,
                        label: _isSaving ? 'Saving...' : 'Save as Image',
                        onTap: _saveAndShareImage),
                    Divider(color: const Color(0xFFFFFDD0).withOpacity(0.1)),
                    const SizedBox(height: 16),
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

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width:  54, height: 54,
          decoration: BoxDecoration(
            color:  color.withOpacity(0.15),
            shape:  BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color: const Color(0xFFFFFDD0).withOpacity(0.6), fontSize: 10)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFFFFDD0).withOpacity(0.8), size: 20),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  color: const Color(0xFFFFFDD0).withOpacity(0.8), fontSize: 15)),
          const Spacer(),
          Icon(Icons.chevron_right,
              color: const Color(0xFFFFFDD0).withOpacity(0.3)),
        ]),
      ),
    );
  }
}
