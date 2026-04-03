import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/verse_cubit.dart';
import '../cubit/verse_state.dart';
import 'audio_screen.dart';

class ResultScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerseCubit()
        ..fetchVerses(
          text: userText,
          emotion: emotion,
          cause: cause,
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: SafeArea(
          child: Column(
            children: [
              // --- Header ---
              Container(
                width: double.infinity,
                color: const Color(0xFF1a3a2a),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                                color: Color(0xFF9fd4b0), fontSize: 12)),
                        Text('Your Verses',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ],
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
                            Text('Finding your verses...',
                                style: TextStyle(color: Colors.grey)),
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
                                  style:
                                      const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<VerseCubit>().fetchVerses(
                                          text: userText,
                                          emotion: emotion,
                                          cause: cause,
                                        ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF1a3a2a)),
                                child: const Text('Retry',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is VerseSuccess) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.verses.length,
                        itemBuilder: (context, index) {
                          final verse = state.verses[index];
                          final isTop = index == 0;
                          return _VerseCard(
                            verse: verse,
                            isTop: isTop,
                            onPlay: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudioScreen(
                                  verses: state.verses,
                                  initialIndex: index,
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
// _VerseCard widget
// ─────────────────────────────────────────
class _VerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;
  final bool isTop;
  final VoidCallback onPlay;

  const _VerseCard({
    required this.verse,
    required this.isTop,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFf0f7f3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isTop ? const Color(0xFFc8e6d4) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Rank + Score row
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
                  child: Text(
                    'Rank ${verse['rank']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  'Score: ${verse['score']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isTop
                        ? const Color(0xFF5a8a6a)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Arabic text
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse['arabic_text'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isTop
                      ? const Color(0xFF1a3a2a)
                      : Colors.black87,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // English verse
            Text(
              verse['verse_text'] ?? '',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isTop
                    ? const Color(0xFF1a3a2a)
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // Surah + Ayah
            Text(
              'Surah ${verse['surah']}  •  Ayah ${verse['ayah']}',
              style: TextStyle(
                fontSize: 12,
                color: isTop
                    ? const Color(0xFF5a8a6a)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),

            // Tags
            Text(
              '${verse['emotion']}  ·  ${verse['cause']}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Play button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPlay,
                icon: Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: isTop
                      ? const Color(0xFF1a3a2a)
                      : Colors.grey.shade700,
                ),
                label: Text(
                  'Play Audio',
                  style: TextStyle(
                    fontSize: 13,
                    color: isTop
                        ? const Color(0xFF1a3a2a)
                        : Colors.grey.shade700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isTop
                        ? const Color(0xFF1a3a2a)
                        : Colors.grey.shade400,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}