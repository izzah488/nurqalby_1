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
        // Auto-play next verse when done
        if (state.processingState == ProcessingState.completed) {
          _nextVerse();
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
    if (isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
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
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [

            // --- Header ---
            Container(
              width: double.infinity,
              color: const Color(0xFF1a3a2a),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Color(0xFF9fd4b0), size: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text('Now playing',
                      style: TextStyle(
                          color: Color(0xFF9fd4b0), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    verse['verse_text'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                  // arab text
                    Text(
                      verse['arabic_text'] ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                      color: Color(0xFF9fd4b0),
                      fontSize: 16,
                      height: 1.8),
),
                  const SizedBox(height: 6),
                  Text(
                    'Surah ${verse['surah']}  •  Ayah ${verse['ayah']}',
                    style: const TextStyle(
                        color: Color(0xFF9fd4b0), fontSize: 13),
                  ),
                ],
              ),
            ),

            // --- Player ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Progress bar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf0f7f3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFc8e6d4)),
                      ),
                      child: Column(
                        children: [

                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  const Color(0xFF1a3a2a),
                              inactiveTrackColor:
                                  const Color(0xFFc8e6d4),
                              thumbColor: const Color(0xFF1a3a2a),
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
                                      .clamp(0,
                                          duration.inSeconds.toDouble())
                                  : 0,
                              min: 0,
                              max: duration.inSeconds > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1,
                              onChanged: (val) {
                                _player.seek(
                                    Duration(seconds: val.toInt()));
                              },
                            ),
                          ),

                          // Time labels
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5a8a6a))),
                                Text(_formatDuration(duration),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5a8a6a))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              // Prev
                              IconButton(
                                onPressed: currentIndex > 0
                                    ? _prevVerse
                                    : null,
                                icon: Icon(
                                  Icons.skip_previous_rounded,
                                  size: 32,
                                  color: currentIndex > 0
                                      ? const Color(0xFF1a3a2a)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Play/Pause
                              GestureDetector(
                                onTap: _togglePlay,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1a3a2a),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Next
                              IconButton(
                                onPressed: currentIndex <
                                        widget.verses.length - 1
                                    ? _nextVerse
                                    : null,
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  size: 32,
                                  color: currentIndex <
                                          widget.verses.length - 1
                                      ? const Color(0xFF1a3a2a)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Verse counter
                    Text(
                      'Verse ${currentIndex + 1} of ${widget.verses.length}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                    const Spacer(),

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.popUntil(context,
                                (route) => route.isFirst),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF1a3a2a)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          '← Try another feeling',
                          style: TextStyle(
                              color: Color(0xFF1a3a2a), fontSize: 14),
                        ),
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