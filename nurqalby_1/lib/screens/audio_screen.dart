import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioScreen extends StatefulWidget {
  final List<Map<String, dynamic>> verses;
  final int initialIndex;

  const AudioScreen({
    super.key,
    required this.verses,
    required this.initialIndex,
  });

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  late AudioPlayer _player;
  late int currentIndex;
  bool isPlaying = false;
  bool isLooping  = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _player      = AudioPlayer();
    _setupListeners();
    _loadAudio();
  }

  void _setupListeners() {
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => position = pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted) setState(() => duration = dur ?? Duration.zero);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          if (isLooping) {
            _player.seek(Duration.zero);
            _player.play();
          } else {
            _nextVerse();
          }
        }
      }
    });
  }

  Future<void> _loadAudio() async {
    final url = widget.verses[currentIndex]['audio_url'] as String;
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio error: $e')),
        );
      }
    }
  }

  void _togglePlay() {
    if (isPlaying) { _player.pause(); } else { _player.play(); }
  }

  void _toggleLoop() {
    setState(() => isLooping = !isLooping);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(isLooping ? 'Repeat ON' : 'Repeat OFF'),
        backgroundColor: const Color(0xFF1a3a2a),
        duration:        const Duration(seconds: 1),
      ),
    );
  }

  void _nextVerse() {
    if (currentIndex < widget.verses.length - 1) {
      setState(() => currentIndex++);
      _loadAudio();
    }
  }

  void _prevVerse() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _loadAudio();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verse = widget.verses[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0d2016),
      body: SafeArea(
        child: Column(
          children: [

            // ── Fixed top bar (never scrolls away) ─────────
            Container(
              color:   const Color(0xFF1a3a2a),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Color(0xFF9fd4b0), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text('Now playing',
                      style: TextStyle(
                          color:      Color(0xFF9fd4b0),
                          fontSize:   13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // ── Everything else scrolls ─────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [

                    // Verse info card
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color:        const Color(0xFF142d1e),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2d5a3d)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // English verse — no maxLines, no ellipsis
                          Text(
                            verse['verse_text'] ?? '',
                            style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   15,
                                fontWeight: FontWeight.w600,
                                height:     1.6),
                          ),
                          const SizedBox(height: 16),

                          Container(height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                Color(0xFF4CAF50),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Arabic verse — right to left, full text
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              verse['arabic_text'] ?? '',
                              style: const TextStyle(
                                  color:      Color(0xFF9fd4b0),
                                  fontSize:   18,
                                  height:     1.9),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Surah info
                          Text(
                            'Surah ${verse['surah']}  •  Ayah ${verse['ayah']}',
                            style: const TextStyle(
                                color:      Color(0xFF4CAF50),
                                fontSize:   12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Player controls card ────────────────
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color:        const Color(0xFF142d1e),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2d5a3d)),
                      ),
                      child: Column(
                        children: [

                          // Progress slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:   const Color(0xFF4CAF50),
                              inactiveTrackColor: const Color(0xFF2d5a3d),
                              thumbColor:         const Color(0xFF4CAF50),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                            ),
                            child: Slider(
                              value: duration.inSeconds > 0
                                  ? position.inSeconds
                                      .toDouble()
                                      .clamp(0, duration.inSeconds.toDouble())
                                  : 0,
                              min: 0,
                              max: duration.inSeconds > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1,
                              onChanged: (val) =>
                                  _player.seek(Duration(seconds: val.toInt())),
                            ),
                          ),

                          // Time labels
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position),
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF9fd4b0))),
                                Text(_formatDuration(duration),
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF9fd4b0))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Playback controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: currentIndex > 0 ? _prevVerse : null,
                                icon: Icon(Icons.skip_previous_rounded,
                                  size:  36,
                                  color: currentIndex > 0
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.2)),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _togglePlay,
                                child: Container(
                                  width: 68, height: 68,
                                  decoration: BoxDecoration(
                                    color:  const Color(0xFF4CAF50),
                                    shape:  BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:      const Color(0xFF4CAF50).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset:     const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white, size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: currentIndex < widget.verses.length - 1
                                    ? _nextVerse
                                    : null,
                                icon: Icon(Icons.skip_next_rounded,
                                  size:  36,
                                  color: currentIndex < widget.verses.length - 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.2)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Verse counter + Repeat button row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Verse ${currentIndex + 1} of ${widget.verses.length}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:    Colors.white.withOpacity(0.4)),
                              ),
                              GestureDetector(
                                onTap: _toggleLoop,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isLooping
                                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isLooping
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.repeat_rounded,
                                        size:  16,
                                        color: isLooping
                                            ? const Color(0xFF4CAF50)
                                            : Colors.white.withOpacity(0.4)),
                                      const SizedBox(width: 5),
                                      Text(
                                        isLooping ? 'Repeat ON' : 'Repeat',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isLooping
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isLooping
                                              ? const Color(0xFF4CAF50)
                                              : Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                        style: OutlinedButton.styleFrom(
                          side:    const BorderSide(color: Color(0xFF4CAF50)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape:   RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('← Try another feeling',
                            style: TextStyle(
                                color: Color(0xFF4CAF50), fontSize: 14)),
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