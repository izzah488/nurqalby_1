import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../cubit/verse_cubit.dart';
import '../cubit/verse_state.dart';
import '../services/dua_service.dart';
import 'share_screen.dart';
import 'audio_screen.dart';
import 'doa_detail_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerseCubit()
        ..fetchVerses(
          text:    widget.userText,
          emotion: widget.emotion,
          cause:   widget.cause,
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(
          child: Column(
            children: [

              // --- Header + Tabs ---
              Container(
                color: const Color(0xFF1a3a2a),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recommended for you',
                                  style: TextStyle(
                                      color: Color(0xFF9fd4b0),
                                      fontSize: 12)),
                              Text('Your Results',
                                  style: TextStyle(
                                      color:      Colors.white,
                                      fontSize:   18,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(), // Pushes the home button to the right

                          // Home button
                          GestureDetector(
                            onTap: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (route) => false,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:        Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.home_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Row(
                        children: [
                          _TabButton(
                            label:      '📖  Verses',
                            isSelected: _selectedTab == 0,
                            onTap: () =>
                                setState(() => _selectedTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _TabButton(
                            label:      '🤲  Dua',
                            isSelected: _selectedTab == 1,
                            onTap: () =>
                                setState(() => _selectedTab = 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Body ---
              Expanded(
                child: BlocBuilder<VerseCubit, VerseState>(
                  builder: (context, state) {
                    if (state is VerseLoading) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: Color(0xFF1a3a2a)),
                            SizedBox(height: 12),
                            Text('Finding your results...',
                                style:
                                    TextStyle(color: Colors.grey)),
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
                              const Icon(Icons.wifi_off,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<VerseCubit>()
                                    .fetchVerses(
                                      text:    widget.userText,
                                      emotion: widget.emotion,
                                      cause:   widget.cause,
                                    ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF1a3a2a)),
                                child: const Text('Retry',
                                    style: TextStyle(
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is VerseSuccess) {
                      final duas =
                          DuaService.getDuasByEmotion(widget.emotion);

                      return _selectedTab == 0
                          // ── VERSES TAB ──
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.verses.length,
                              itemBuilder: (context, index) {
                                final verse = state.verses[index];
                                final isTop = index == 0;
                                return _VerseCard(
                                  verse:  verse,
                                  isTop:  isTop,
                                  onPlay: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AudioScreen(
                                        verses:       state.verses,
                                        initialIndex: index,
                                      ),
                                    ),
                                  ),
                                  onShare: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ShareScreen(verse: verse),
                                    ),
                                  ),
                                );
                              },
                            )
                          // ── DUA TAB ──
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: duas.length,
                              itemBuilder: (context, index) {
                                return _DuaCard(
                                  dua: duas[index],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DoaDetailScreen(
                                        arabic:      duas[index]['arabic_text'] ?? duas[index]['arabic']!,
                                        translation: duas[index]['english_text'] ?? duas[index]['translation']!,
                                        prayerName:  widget.emotion,
                                      ),
                                    ),
                                  ),
                                );
                              },
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

// ─────────────────────────────────────────
// Tab button
// ─────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:  const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1a3a2a)
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Verse card
// ─────────────────────────────────────────
class _VerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;
  final bool         isTop;
  final VoidCallback onPlay;
  final VoidCallback onShare;

  const _VerseCard({
    required this.verse,
    required this.isTop,
    required this.onPlay,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFf0f7f3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop
              ? const Color(0xFFc8e6d4)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTop
                        ? const Color(0xFF1a3a2a)
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Rank ${verse['rank']}',
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   11,
                          fontWeight: FontWeight.w500)),
                ),
                Text('Score: ${verse['score']}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isTop
                            ? const Color(0xFF5a8a6a)
                            : Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse['arabic_text'] ?? '',
                style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w600,
                    color: isTop
                        ? const Color(0xFF1a3a2a)
                        : Colors.black87,
                    height: 1.8),
              ),
            ),
            const SizedBox(height: 8),

            Text(verse['verse_text'] ?? '',
                style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w600,
                    color: isTop
                        ? const Color(0xFF1a3a2a)
                        : Colors.black87)),
            const SizedBox(height: 4),

            Text(
                'Surah ${verse['surah']}  •  Ayah ${verse['ayah']}',
                style: TextStyle(
                    fontSize: 12,
                    color: isTop
                        ? const Color(0xFF5a8a6a)
                        : Colors.grey)),
            const SizedBox(height: 4),

            Text('${verse['emotion']}  ·  ${verse['cause']}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPlay,
                    icon: Icon(Icons.play_circle_outline,
                        size:  18,
                        color: isTop
                            ? const Color(0xFF1a3a2a)
                            : Colors.grey.shade700),
                    label: Text('Play Audio',
                        style: TextStyle(
                            fontSize: 13,
                            color: isTop
                                ? const Color(0xFF1a3a2a)
                                : Colors.grey.shade700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isTop
                              ? const Color(0xFF1a3a2a)
                              : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: Icon(Icons.share_rounded,
                        size:  18,
                        color: Colors.grey.shade700),
                    label: Text('Share',
                        style: TextStyle(
                            fontSize: 13,
                            color:    Colors.grey.shade700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Dua card — tap opens detail screen
// ─────────────────────────────────────────
class _DuaCard extends StatelessWidget {
  final Map<String, String> dua;
  final VoidCallback        onTap;

  const _DuaCard({
    required this.dua,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        const Color(0xFFf7f0ff),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFd4b8f0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title
            if (dua['title'] != null && dua['title']!.isNotEmpty) ...[
              Text(
                dua['title']!,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF3a1a6a)),
              ),
              const SizedBox(height: 8),
            ],

            // Arabic
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                dua['arabic_text'] ?? dua['arabic'] ?? '',
                style: const TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF3a1a6a),
                    height:     1.8),
              ),
            ),
            const SizedBox(height: 8),

            // Translation / English
            Text(
              dua['english_text'] ?? dua['translation'] ?? '',
              style: const TextStyle(
                  fontSize: 13,
                  color:    Color(0xFF5a3a8a),
                  height:   1.5),
            ),
            const SizedBox(height: 4),

            // Reference
            Text(
              dua['reference'] ?? '',
              style: TextStyle(
                  fontSize:  11,
                  color:     Colors.grey.shade500,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),

            // Tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Tap to read more',
                    style: TextStyle(
                        fontSize: 11,
                        color:    Colors.grey.shade400)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size:  11,
                    color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}