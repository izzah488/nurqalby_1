import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import '../cubit/verse_cubit.dart';
import '../cubit/verse_state.dart';
import '../services/dua_service.dart';
import 'audio_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String userText;
  final String emotion;
  final String cause;

  const ResultScreen({
    super.key,
    required this.userText,
    required this.emotion,
    required this.cause,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedTab = 0;
  int _currentIndex = 0;
  late PageController _pageController;
  
  // Stores a unique GlobalKey for each card so we can take a screenshot of it
  final Map<int, GlobalKey> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) {
    _cardKeys[index] ??= GlobalKey();
    return _cardKeys[index]!;
  }

  // --- NEW: Bottom Sheet to choose between Image or Text sharing ---
  void _showShareOptions(BuildContext context, GlobalKey key, String textToShare) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142d1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Color(0xFF4CAF50)),
                title: const Text('Share as Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  _shareAsImage(key, textToShare); // Trigger screenshot
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields_rounded, color: Color(0xFF4CAF50)),
                title: const Text('Share as Text', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  Share.share(textToShare); // Share normal text
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAsImage(GlobalKey key, String fallbackText) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Share.share(fallbackText);
        return;
      }
      
      // Capture the card as an image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        Share.share(fallbackText);
        return;
      }
      
      // Share the image file directly
      await Share.shareXFiles(
        [
          XFile.fromData(
            byteData.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'nurqalby_verse.png',
          )
        ],
        text: 'Shared via NurQalby 🌿',
      );
    } catch (_) {
      // If taking the screenshot fails for any reason, safely fallback to text sharing
      Share.share(fallbackText);
    }
  }

  void _switchTab(int tab) {
    setState(() {
      _selectedTab = tab;
      _currentIndex = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerseCubit()..fetchVerses(
        text: widget.userText,
        emotion: widget.emotion,
        cause: widget.cause,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0d2016),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: const Color(0xFF1a3a2a),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommended for you', style: TextStyle(color: Color(0xFF9fd4b0), fontSize: 12)),
                          Text('Your Results', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                color: const Color(0xFF1a3a2a),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _TabButton(
                      label: '📖  Verses',
                      isSelected: _selectedTab == 0,
                      onTap: () => _switchTab(0),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: '🤲  Dua',
                      isSelected: _selectedTab == 1,
                      onTap: () => _switchTab(1),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<VerseCubit, VerseState>(
                  builder: (context, state) {
                    if (state is VerseLoading) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF4CAF50)),
                            SizedBox(height: 16),
                            Text('Finding your results...', style: TextStyle(color: Color(0xFF9fd4b0))),
                          ],
                        ),
                      );
                    }

                    if (state is VerseError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off, size: 56, color: Colors.white.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => context.read<VerseCubit>().fetchVerses(
                                  text: widget.userText,
                                  emotion: widget.emotion,
                                  cause: widget.cause,
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                                child: const Text('Retry', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is VerseSuccess) {
                      final duas = DuaService.getDuasByEmotion(widget.emotion);
                      final items = _selectedTab == 0 ? state.verses : duas;

                      return Column(
                        children: [
                          const SizedBox(height: 20),

                          // Swipe cards
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: items.length,
                              onPageChanged: (i) => setState(() => _currentIndex = i),
                              itemBuilder: (context, index) {
                                final item = items[index] as Map<String, dynamic>;
                                final isFocused = index == _currentIndex;
                                final cardKey = _keyFor(index);

                                return AnimatedScale(
                                  scale: isFocused ? 1.0 : 0.88,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedOpacity(
                                    opacity: isFocused ? 1.0 : 0.55,
                                    duration: const Duration(milliseconds: 300),
                                    child: RepaintBoundary(
                                      key: cardKey,
                                      child: _selectedTab == 0
                                          ? _VerseCard(
                                              verse: item,
                                              isFocused: isFocused,
                                              rank: index + 1,
                                              onShare: () {
                                                String text = '${item['arabic_text']}\n\n"${item['verse_text']}"\n\nSurah ${item['surah']} • Ayah ${item['ayah']}\n\nShared via NurQalby 🌿';
                                                _showShareOptions(context, cardKey, text);
                                              },
                                            )
                                          : _DuaCard(
                                              dua: item,
                                              isFocused: isFocused,
                                              onShare: () {
                                                String text = '${item['arabic'] ?? ''}\n\n"${item['translation'] ?? ''}"\n\n— ${item['reference'] ?? ''}\n\nShared via NurQalby 🌿';
                                                _showShareOptions(context, cardKey, text);
                                              },
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              items.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _currentIndex ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _currentIndex ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bottom actions
                          _BottomActions(
                            verses: state.verses,
                            duas: duas,
                            currentIndex: _currentIndex,
                            selectedTab: _selectedTab,
                            onSwitchTab: _switchTab,
                            onPlay: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudioScreen(verses: state.verses, initialIndex: _currentIndex),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab button ───────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF1a3a2a) : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Verse card ───────────────────────────
class _VerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;
  final bool isFocused;
  final int rank;
  final VoidCallback onShare;

  const _VerseCard({required this.verse, required this.isFocused, required this.rank, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142d1e),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isFocused ? const Color(0xFF4CAF50).withOpacity(0.5) : const Color(0xFF2d5a3d), width: isFocused ? 1.5 : 1),
        boxShadow: isFocused ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Chip(label: rank == 1 ? 'RANK 1 · BEST' : 'RANK $rank', isDua: false),
                if (verse['score'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: Text('${verse['score']}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    verse['arabic_text'] ?? '',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Divider(color: Color(0xFF3d6b4a)),
            const SizedBox(height: 12),
            Text(
              '"${verse['verse_text'] ?? ''}"',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            
            // Text at the bottom
            Text(
              'SURAH ${verse['surah']}  •  AYAH ${verse['ayah']}',
              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Beautiful full-width Share button at the very bottom
            GestureDetector(
              onTap: onShare,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

// ── Dua card ─────────────────────────────
class _DuaCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  final bool isFocused;
  final VoidCallback onShare;

  const _DuaCard({required this.dua, required this.isFocused, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1428),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isFocused ? const Color(0xFFb088f0).withOpacity(0.5) : const Color(0xFF3d2d5a), width: isFocused ? 1.5 : 1),
        boxShadow: isFocused ? [BoxShadow(color: const Color(0xFF9c6fdf).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              children: [
                _Chip(label: 'DUA', isDua: true),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    dua['arabic'] ?? '',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Divider(color: Color(0xFF5a3a8a)),
            const SizedBox(height: 12),
            Text(
              '"${dua['translation'] ?? ''}"',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.6, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),

            // Text at the bottom
            Text(
              dua['reference'] ?? '',
              style: const TextStyle(color: Color(0xFFb088f0), fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Beautiful full-width Share button at the very bottom
            GestureDetector(
              onTap: onShare,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

// ── Bottom actions ────────────────────────
class _BottomActions extends StatefulWidget {
  final List<Map<String, dynamic>> verses, duas;
  final int currentIndex, selectedTab;
  final Function(int) onSwitchTab;
  final VoidCallback onPlay;

  const _BottomActions({
    required this.verses,
    required this.duas,
    required this.currentIndex,
    required this.selectedTab,
    required this.onSwitchTab,
    required this.onPlay,
  });

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions> {
  final Set<String> _savedKeys = {};

  String get _key {
    final item = widget.selectedTab == 0
        ? widget.verses[widget.currentIndex]
        : widget.duas[widget.currentIndex];
    return '${widget.selectedTab == 0 ? 'verse' : 'dua'}_${item['arabic_text'] ?? item['arabic'] ?? ''}';
  }

  // BUG FIX: This dynamic getter automatically checks the new verse every time you swipe!
  bool get _isSaved => _savedKeys.contains(_key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    if (!mounted) return;
    setState(() {
      _savedKeys.clear();
      for (final s in saved) {
        final m = jsonDecode(s);
        if (m['key'] != null) _savedKeys.add(m['key']);
      }
    });
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final key = _key;
    final isVerse = widget.selectedTab == 0;
    final item = isVerse ? widget.verses[widget.currentIndex] : widget.duas[widget.currentIndex];

    if (_isSaved) {
      saved.removeWhere((s) => jsonDecode(s)['key'] == key);
      setState(() => _savedKeys.remove(key));
    } else {
      saved.add(jsonEncode({
        'key': key,
        'type': isVerse ? 'verse' : 'dua',
        'title': isVerse ? 'Surah ${item['surah']} Ayah ${item['ayah']}' : (item['title'] ?? ''),
        'arabic': item['arabic_text'] ?? item['arabic'] ?? '',
        'english': item['verse_text'] ?? item['translation'] ?? '',
        'reference': isVerse ? 'Surah ${item['surah']}, Ayah ${item['ayah']}' : (item['reference'] ?? ''),
      }));
      setState(() => _savedKeys.add(key));
    }

    await prefs.setStringList('saved_items', saved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSaved ? 'Saved ✓' : 'Removed'),
        backgroundColor: const Color(0xFF1a3a2a),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerse = widget.selectedTab == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Btn(
            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: 'SAVE',
            color: _isSaved ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.4),
            bgColor: _isSaved ? const Color(0xFF1a3a2a) : const Color(0xFF142d1e),
            border: _isSaved ? const Color(0xFF4CAF50) : const Color(0xFF2d5a3d),
            onTap: _toggleSave,
          ),
          _Btn(
            icon: Icons.play_arrow_rounded, label: isVerse ? 'PLAY' : '—',
            color: Colors.white,
            bgColor: isVerse ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.1),
            border: Colors.transparent, size: 64, isMain: true,
            onTap: isVerse ? widget.onPlay : null,
          ),
          _Btn(
            icon: isVerse ? Icons.volunteer_activism_rounded : Icons.menu_book_rounded,
            label: isVerse ? 'DUA' : 'VERSE',
            color: Colors.white.withOpacity(0.4),
            bgColor: const Color(0xFF1e1428),
            border: const Color(0xFF3d2d5a),
            onTap: () => widget.onSwitchTab(isVerse ? 1 : 0),
          ),
        ],
      ),
    );
  }
}

// ── Micro widgets ─────────────────────────
class _Chip extends StatelessWidget {
  final String label; final bool isDua;
  const _Chip({required this.label, required this.isDua});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isDua ? const Color(0xFF2a1a3a) : const Color(0xFF1a3a2a),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: isDua ? const Color(0xFF5a3a8a) : const Color(0xFF3d6b4a)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (isDua) const Text('🤲', style: TextStyle(fontSize: 10))
      else Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: isDua ? const Color(0xFFd4b8f0) : const Color(0xFF9fd4b0), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) => Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, color, Colors.transparent])));
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label;
  final Color color, bgColor, border;
  final double size; final VoidCallback? onTap; final bool isMain;
  const _Btn({required this.icon, required this.label, required this.color, required this.bgColor, required this.border, this.size = 52, this.onTap, this.isMain = false});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Column(children: [
      AnimatedContainer(duration: const Duration(milliseconds: 200), width: size, height: size,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(isMain ? 20 : 16), border: Border.all(color: border),
        boxShadow: isMain ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))] : []),
        child: Icon(icon, color: color, size: isMain ? 28 : 22)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
    ]));
}