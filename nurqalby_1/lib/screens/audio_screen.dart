import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioScreen extends StatefulWidget {
  final List<Map<String, dynamic>> verses;
  final int initialIndex;
  final bool fromSaved;

  const AudioScreen({
    super.key,
    required this.verses,
    required this.initialIndex,
    this.fromSaved = false,
  });

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  late int currentIndex;
  bool isPlaying = false;
  bool isLooping = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  late AnimationController _pulseController;
  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // ── colours ──────────────────────────────────────────────────────────────
  static const Color _bg1 = Color(0xFF12022A);
  static const Color _bg2 = Color(0xFF2D1B4E);
  static const Color _purple = Color(0xFF9966CC);
  static const Color _lavender = Color(0xFFBB86FC);
  static const Color _green = Color(0xFF7FB883);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _player = AudioPlayer();

    // pulsing glow for play button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // card entrance / transition
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));
    _cardController.forward();

    _setupListeners();
    _loadAudio();
  }

  // ── audio listeners ───────────────────────────────────────────────────────
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

  // ── controls ──────────────────────────────────────────────────────────────
  void _togglePlay() =>
      isPlaying ? _player.pause() : _player.play();

  void _toggleLoop() {
    setState(() => isLooping = !isLooping);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isLooping ? '🔁  Repeat ON' : 'Repeat OFF'),
      backgroundColor: _bg2,
      duration: const Duration(seconds: 1),
    ));
  }

  void _nextVerse() {
    if (currentIndex < widget.verses.length - 1) {
      _cardController.reverse().then((_) {
        if (mounted) {
          setState(() => currentIndex++);
          _cardController.forward();
          _loadAudio();
        }
      });
    }
  }

  void _prevVerse() {
    if (currentIndex > 0) {
      _cardController.reverse().then((_) {
        if (mounted) {
          setState(() => currentIndex--);
          _cardController.forward();
          _loadAudio();
        }
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final verse = widget.verses[currentIndex];

    return Scaffold(
      backgroundColor: _bg1,
      body: Stack(
        children: [
          // ── BACKGROUND IMAGE (asset) ────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgaudio.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Light dark tint so text stays readable ─────────────────────
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.22)),
          ),

          // ── content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // top bar
                _buildTopBar(),

                // verse card (the "album art")
                Expanded(
                  flex: 52,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _buildVerseCard(verse),
                      ),
                    ),
                  ),
                ),

                // player section
                Expanded(
                  flex: 48,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    child: _buildPlayer(verse),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          _glassButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          // placeholder to keep title centred
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ── verse card (NOW FULL PICTURE BACKGROUND) ─────────────────────────────
  Widget _buildVerseCard(Map<String, dynamic> verse) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          // FULL BACKGROUND IMAGE covering entire card
          Positioned.fill(
            child: Image.asset(
              'assets/images/verse1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Glass overlay with border and shadow (keeps original design)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.0),
                    blurRadius: 40,
                    spreadRadius: -4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),

          // Content overlay (text, badges, etc.)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // surah badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBB86FC), Color(0xFF7B2FBE)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withOpacity(0.55),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'Surah ${verse['surah']}  ·  Ayah ${verse['ayah']}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Arabic text
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    verse['arabic_text'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 21,
                      height: 2.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // shimmer divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _lavender.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // English text
                Text(
                  verse['verse_text'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.82),
                    fontSize: 13,
                    height: 1.75,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── player ────────────────────────────────────────────────────────────────
  Widget _buildPlayer(Map<String, dynamic> verse) {
    final progress = duration.inSeconds > 0
        ? position.inSeconds
            .toDouble()
            .clamp(0.0, duration.inSeconds.toDouble())
        : 0.0;
    final maxVal =
        duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Verse Counter
        Text(
          'Verse ${currentIndex + 1} of ${widget.verses.length}',
          style: TextStyle(
              color: Colors.black.withOpacity(0.4), 
              fontSize: 12, 
              fontWeight: FontWeight.w500
          ),
        ),
        const SizedBox(height: 14),

        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7B2FBE),
            inactiveTrackColor: Colors.black.withOpacity(0.05),
            thumbColor: Colors.white,
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8, elevation: 3),
            overlayColor: const Color(0xFF7B2FBE).withOpacity(0.1),
          ),
          child: Slider(
            value: progress,
            min: 0,
            max: maxVal,
            onChanged: (val) =>
                _player.seek(Duration(seconds: val.toInt())),
          ),
        ),

        // Time Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position),
                  style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text(_fmt(duration),
                  style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Main Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Spacer: Balances the Repeat button width (40) + its margin (18)
            const SizedBox(width: 58),

            // Previous Button
            IconButton(
              iconSize: 44,
              onPressed: currentIndex > 0 ? _prevVerse : null,
              icon: Icon(
                Icons.skip_previous_rounded,
                color: currentIndex > 0 ? Colors.black : Colors.black12,
              ),
            ),
            const SizedBox(width: 8),

            // Play / Pause (The Centerpiece)
            GestureDetector(
              onTap: _togglePlay,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFCB9FFF), Color(0xFF7B2FBE)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FBE).withOpacity(
                            0.3 + 0.2 * _pulseController.value),
                        blurRadius: 20 + 10 * _pulseController.value,
                        spreadRadius: isPlaying ? 4 * _pulseController.value : 0,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Next Button
            IconButton(
              iconSize: 44,
              onPressed: currentIndex < widget.verses.length - 1 ? _nextVerse : null,
              icon: Icon(
                Icons.skip_next_rounded,
                color: currentIndex < widget.verses.length - 1 ? Colors.black : Colors.black12,
              ),
            ),
            const SizedBox(width: 18),

            // Repeat Button (Right Side)
            GestureDetector(
              onTap: _toggleLoop,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLooping ? const Color(0xFF7B2FBE).withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: isLooping ? const Color(0xFF7B2FBE) : Colors.black12,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 20,
                  color: isLooping ? const Color(0xFF7B2FBE) : Colors.black38,
                ),
              ),
            ),
          ],
        ),

        // Secondary Action: Try another feeling (ONLY if NOT from saved)
        if (!widget.fromSaved) ...[
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF7B2FBE)),
                const SizedBox(width: 8),
                Text(
                  'Try another feeling',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _glassButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 12, 9, 9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color.fromARGB(255, 7, 6, 6).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}