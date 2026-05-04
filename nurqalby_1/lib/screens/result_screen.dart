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
  bool _isSharing = false; 
  late PageController _pageController;
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

  void _showShareOptions(BuildContext context, GlobalKey key, String textToShare) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEDE5F8),
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
                  color: const Color(0xFF2D1B4E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Color(0xFF9966CC)),
                title: const Text('Share as Image',
                    style: TextStyle(color: Color(0xFF2D1B4E), fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsImage(key, textToShare);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields_rounded, color: Color(0xFF9966CC)),
                title: const Text('Share as Text',
                    style: TextStyle(color: Color(0xFF2D1B4E), fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(textToShare);
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
    setState(() => _isSharing = true);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Share.share(fallbackText);
      } else {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          Share.share(fallbackText);
        } else {
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
        }
      }
    } catch (_) {
      Share.share(fallbackText);
    } finally {
      if (mounted) setState(() => _isSharing = false);
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
      create: (_) => VerseCubit()
        ..fetchVerses(
          text: widget.userText,
          emotion: widget.emotion,
          cause: widget.cause,
        ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bgresult.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D1B4E), size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recommended for you',
                                  style: TextStyle(color: Color(0xFF7B5EA7), fontSize: 12, fontWeight: FontWeight.w500)),
                              Text('Your Results',
                                  style: TextStyle(color: Color(0xFF2D1B4E), fontSize: 20, fontWeight: FontWeight.bold)),
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
                              color: const Color(0xFF2D1B4E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home_rounded, color: Color(0xFF2D1B4E), size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: '📖  Verses',
                            isSelected: _selectedTab == 0,
                            onTap: () => _switchTab(0),
                          ),
                          const SizedBox(width: 4),
                          _TabButton(
                            label: '🤲  Dua',
                            isSelected: _selectedTab == 1,
                            onTap: () => _switchTab(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<VerseCubit, VerseState>(
                      builder: (context, state) {
                        if (state is VerseLoading) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF9966CC)));
                        }
                        if (state is VerseError) return Center(child: Text(state.message));
                        if (state is VerseSuccess) {
                          final duas = DuaService.getDuasByEmotion(widget.emotion);
                          final items = _selectedTab == 0 ? state.verses : duas;

                          return Column(
                            children: [
                              const SizedBox(height: 10),
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
                                      child: RepaintBoundary(
                                        key: cardKey,
                                        child: _selectedTab == 0
                                            ? _VerseCard(
                                                verse: item,
                                                isFocused: isFocused,
                                                isSharing: _isSharing,
                                                rank: index + 1,
                                                onShare: () {
                                                  final text = '${item['arabic_text']}\n\n"${item['verse_text']}"\n\nSurah ${item['surah']} • Ayah ${item['ayah']}';
                                                  _showShareOptions(context, cardKey, text);
                                                },
                                              )
                                            : _DuaCard(
                                                dua: item,
                                                isFocused: isFocused,
                                                isSharing: _isSharing,
                                                rank: index + 1,
                                                onShare: () {
                                                  final text = '${item['arabic']}\n\n"${item['translation']}"\n\n— ${item['reference']}';
                                                  _showShareOptions(context, cardKey, text);
                                                },
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                      color: i == _currentIndex ? const Color(0xFF9966CC) : Colors.black26,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}

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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D1B4E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2D1B4E).withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;
  final bool isFocused;
  final bool isSharing;
  final int rank;
  final VoidCallback onShare;

  const _VerseCard({required this.verse, required this.isFocused, required this.isSharing, required this.rank, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      image: 'assets/images/verse1.jpg',
      isFocused: isFocused,
      isSharing: isSharing,
      chipLabel: 'RANK $rank · BEST',
      arabicText: verse['arabic_text'] ?? '',
      bodyText: '"${verse['verse_text'] ?? ''}"',
      refText: 'SURAH ${verse['surah']} • AYAH ${verse['ayah']}',
      onShare: onShare,
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Map<String, dynamic> dua;
  final bool isFocused;
  final bool isSharing;
  final int rank;
  final VoidCallback onShare;

  const _DuaCard({required this.dua, required this.isFocused, required this.isSharing, required this.rank, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      image: 'assets/images/dua1.jpg',
      isFocused: isFocused,
      isSharing: isSharing,
      chipLabel: 'DUA · $rank',
      arabicText: dua['arabic'] ?? '',
      bodyText: '"${dua['translation'] ?? ''}"',
      refText: dua['reference'] ?? '',
      onShare: onShare,
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String image;
  final bool isFocused;
  final bool isSharing;
  final String chipLabel;
  final String arabicText;
  final String bodyText;
  final String refText;
  final VoidCallback onShare;

  const _ContentCard({
    required this.image,
    required this.isFocused,
    required this.isSharing,
    required this.chipLabel,
    required this.arabicText,
    required this.bodyText,
    required this.refText,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: Colors.white.withOpacity(0.35))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9966CC).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(chipLabel, style: const TextStyle(color: Color(0xFF9966CC), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Centered and Scrollable Logic
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              arabicText,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold, height: 1.8),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              bodyText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87, fontSize: 14, fontStyle: FontStyle.italic, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(refText, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  if (!isSharing)
                    GestureDetector(
                      onTap: onShare,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ios_share_rounded, color: Colors.black, size: 18),
                            SizedBox(width: 10),
                            Text("Share Moment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  String get _currentKey {
    final item = widget.selectedTab == 0 ? widget.verses[widget.currentIndex] : widget.duas[widget.currentIndex];
    return '${widget.selectedTab}_${item['arabic_text'] ?? item['arabic'] ?? ''}';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    if (!mounted) return;
    setState(() {
      _savedKeys.clear();
      for (var s in saved) {
        final m = jsonDecode(s);
        if (m['key'] != null) _savedKeys.add(m['key']);
      }
    });
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final key = _currentKey;
    final isVerse = widget.selectedTab == 0;
    final item = isVerse ? widget.verses[widget.currentIndex] : widget.duas[widget.currentIndex];

    bool nowSaved;
    if (_savedKeys.contains(key)) {
      saved.removeWhere((s) => jsonDecode(s)['key'] == key);
      _savedKeys.remove(key);
      nowSaved = false;
    } else {
      saved.add(jsonEncode({
        'key':       key,
        'type':      isVerse ? 'verse' : 'dua',
        'title':     isVerse ? 'Surah ${item['surah']} Ayah ${item['ayah']}' : (item['title'] ?? ''),
        'arabic':    item['arabic_text'] ?? item['arabic'] ?? '',
        'english':   item['verse_text']  ?? item['translation'] ?? '',
        'reference': isVerse ? 'Surah ${item['surah']}, Ayah ${item['ayah']}' : (item['reference'] ?? ''),
        // ── ADDED: store audio_url, surah, ayah so AudioScreen works from SavedScreen ──
        'audio_url': isVerse ? (item['audio_url'] ?? '') : '',
        'surah':     isVerse ? '${item['surah']}' : '',
        'ayah':      isVerse ? '${item['ayah']}'  : '',
      }));
      _savedKeys.add(key);
      nowSaved = true;
    }

    await prefs.setStringList('saved_items', saved);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nowSaved ? 'Saved ✓' : 'Removed', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.black.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerse = widget.selectedTab == 0;
    final isSaved = _savedKeys.contains(_currentKey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ImprovedBtn(
            icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: "Save",
            isActive: isSaved,
            onTap: _toggleSave,
          ),
          _ImprovedBtn(
            icon: Icons.play_arrow_rounded,
            label: "Play",
            isLarge: true,
            isDisabled: !isVerse,
            onTap: isVerse ? widget.onPlay : null,
          ),
          _ImprovedBtn(
            icon: isVerse ? Icons.volunteer_activism_rounded : Icons.menu_book_rounded,
            label: isVerse ? "Dua" : "Verse",
            onTap: () => widget.onSwitchTab(isVerse ? 1 : 0),
          ),
        ],
      ),
    );
  }
}

class _ImprovedBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLarge;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ImprovedBtn({
    required this.icon,
    required this.label,
    this.isLarge = false,
    this.isActive = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(255, 93, 61, 125);
    final secondary = const Color(0xFF2D1B4E);
    final disabledColor = const Color.fromARGB(255, 50, 48, 48);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isLarge ? 72 : 58,
            height: isLarge ? 72 : 58,
            decoration: BoxDecoration(
              gradient: isLarge && !isDisabled
                  ? LinearGradient(
                      colors: [primary, primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isDisabled 
                  ? disabledColor.withOpacity(0.3) 
                  : (isLarge ? null : Colors.white.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(isLarge ? 24 : 20),
              border: Border.all(
                color: isDisabled 
                    ? disabledColor.withOpacity(0.5) 
                    : (isActive ? primary : Colors.white.withOpacity(0.3)), 
                width: 1.5,
              ),
              boxShadow: (isLarge && !isDisabled)
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: isLarge ? 32 : 24,
              color: isDisabled 
                  ? disabledColor 
                  : (isLarge ? Colors.white : (isActive ? primary : secondary)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDisabled ? disabledColor : secondary.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          )
        ],
      ),
    );
  }
}