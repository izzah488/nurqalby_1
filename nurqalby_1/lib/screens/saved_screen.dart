import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'notification_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> savedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    setState(() {
      savedItems = saved
          .map((s) => Map<String, dynamic>.from(jsonDecode(s)))
          .toList()
          .reversed
          .toList();
      isLoading = false;
    });
  }

  Future<void> _removeItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    final key = savedItems[index]['key'];
    saved.removeWhere((s) {
      final map = jsonDecode(s);
      return map['key'] == key;
    });
    await prefs.setStringList('saved_items', saved);
    setState(() => savedItems.removeAt(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Removed from saved',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFEDE5F8),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: const Color(0xFFEDE5F8),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Collection',
                      style: TextStyle(color: Color(0xFF7B5EA7), fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Saved Items',
                      style: TextStyle(
                          color: Color(0xFF2D1B4E),
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF9966CC)))
                  : savedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bookmark_outline_rounded,
                                  size: 72,
                                  color: const Color(0xFF2D1B4E)
                                      .withOpacity(0.15)),
                              const SizedBox(height: 16),
                              Text('No saved items yet',
                                  style: TextStyle(
                                      color: const Color(0xFF2D1B4E)
                                          .withOpacity(0.4),
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                'Save verses and duas to find them here',
                                style: TextStyle(
                                    color: const Color(0xFF2D1B4E)
                                        .withOpacity(0.28),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: savedItems.length,
                          itemBuilder: (context, index) {
                            final item = savedItems[index];
                            final isVerse = item['type'] == 'verse';
                            return _SavedCard(
                              key: ValueKey(item['key']),
                              item: item,
                              isVerse: isVerse,
                              onRemove: () => _removeItem(index),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationDetailScreen(
                                    arabic: item['arabic'] ?? '',
                                    english: item['english'] ??
                                        item['translation'] ??
                                        '',
                                    title: item['title'] ??
                                        item['prayerName'] ??
                                        '',
                                    reference: item['reference'] ?? '',
                                    type: item['type'] ?? 'dua',
                                  ),
                                ),
                              ).then((_) => _loadSaved()),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isVerse;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _SavedCard({
    super.key,
    required this.item,
    required this.isVerse,
    required this.onRemove,
    required this.onTap,
  });

  @override
  State<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<_SavedCard> with TickerProviderStateMixin {
  static const double _revealWidth = 80.0;
  static const double _dragThreshold = 55.0;
  static const double _flingThreshold = 300.0;

  double _dragOffset = 0.0;
  bool _isExiting = false;

  late final AnimationController _snapController;
  late Animation<double> _snapAnim;

  late final AnimationController _exitController;
  late final Animation<double> _exitSlide;
  late final Animation<double> _exitOpacity;

  late final AnimationController _collapseController;
  late final Animation<double> _collapse;

  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    _snapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _snapAnim = _snapController.drive(Tween(begin: 0.0, end: 0.0));
    _snapController.addListener(_onSnapTick);

    _exitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _exitSlide = Tween<double>(begin: 0.0, end: -420.0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _exitController,
            curve: const Interval(0.15, 1.0, curve: Curves.easeIn)));

    _collapseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 290));
    _collapse = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _collapseController, curve: Curves.easeInOut));

    _tapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _tapScale = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _snapController.dispose();
    _exitController.dispose();
    _collapseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    if (mounted) setState(() => _dragOffset = _snapAnim.value);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_isExiting) return;
    if (_snapController.isAnimating) _snapController.stop();
    final newOffset =
        (_dragOffset + d.delta.dx).clamp(-_revealWidth * 1.2, 0.0);
    setState(() => _dragOffset = newOffset);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_isExiting) return;
    final velocity = d.primaryVelocity ?? 0.0;
    if (_dragOffset.abs() >= _dragThreshold || velocity < -_flingThreshold) {
      _snapToReveal();
    } else {
      _snapBack();
    }
  }

  void _snapToReveal() {
    final start = _dragOffset;
    _snapController.reset();
    _snapAnim = Tween<double>(begin: start, end: -_revealWidth).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController.forward();
  }

  void _snapBack() {
    final start = _dragOffset;
    _snapController.reset();
    _snapAnim = Tween<double>(begin: start, end: 0.0).animate(
        CurvedAnimation(
            parent: _snapController, curve: Curves.elasticOut));
    _snapController.forward();
  }

  Future<void> _onDeleteTap() async {
    if (_isExiting) return;
    setState(() => _isExiting = true);

    await _tapController.forward();
    if (!mounted) return;
    await _tapController.reverse();
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    await _collapseController.forward();
    if (!mounted) return;

    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final swipeProgress = (_dragOffset.abs() / _revealWidth).clamp(0.0, 1.2);
    final iconScale = 0.65 + 0.55 * swipeProgress;
    final bgOpacity = swipeProgress.clamp(0.0, 1.0);

    return SizeTransition(
      sizeFactor: _collapse,
      axisAlignment: -1.0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_exitController, _tapController]),
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.translate(
              offset: Offset(_exitSlide.value, 0),
              child: Transform.scale(
                scale: _tapScale.value,
                child: child,
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: bgOpacity,
                      child: Container(
                        color: Colors.red.shade400,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        child: GestureDetector(
                          onTap: _onDeleteTap,
                          child: Transform.scale(
                            scale: iconScale,
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: _buildCardContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final item = widget.item;
    final isVerse = widget.isVerse;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4B8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isVerse
                  ? const Color(0xFF9966CC)
                  : const Color(0xFF7B5EA7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4B8E8)),
                      ),
                      child: Text(
                        isVerse ? '📖 Verse' : '🤲 Dua',
                        style: const TextStyle(
                            color: Color(0xFF7B5EA7), fontSize: 11),
                      ),
                    ),
                    // Bookmark icon removed as swipe handles deletion
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                      color: Color(0xFF7B5EA7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item['arabic'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFF2D1B4E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['english'] ?? item['translation'] ?? '',
                  style: TextStyle(
                      color: const Color(0xFF2D1B4E).withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['reference'] ?? '',
                      style: const TextStyle(
                          color: Color(0xFF9966CC), fontSize: 11),
                    ),
                    Text(
                      item['time'] ?? '',
                      style: TextStyle(
                          color: const Color(0xFF2D1B4E).withOpacity(0.3),
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}