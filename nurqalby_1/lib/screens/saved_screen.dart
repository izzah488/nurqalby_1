// lib/screens/saved_screen.dart
//
// CARD DECK UX
// • Cards are stacked on top of each other
// • Only the top card is interactive (gesture-enabled)
// • Next 1–2 cards peek slightly behind (scaled + offset)
// • Swipe RIGHT  → skip to next card
// • Swipe LEFT   → delete with confirm dialog
// • Tap          → open detail screen
// • Filter tabs: All / Verse / Dua
// • Uses SavedCubit — no manual setState for loading/deleting

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import 'dart:math' show min;
import '../cubit/saved_cubit.dart';
import '../cubit/saved_state.dart';
import 'notification_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SavedView();
}

// ─────────────────────────────────────────────────────────────────────────────
class _SavedView extends StatefulWidget {
  const _SavedView();

  @override
  State<_SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<_SavedView> {
  int _currentIndex = 0;

  // Top-card drag values
  double _dragX     = 0.0;
  double _dragY     = 0.0;
  bool   _isDragging = false;

  static const double _swipeThreshold = 100.0;

  static const _bg     = Color(0xFFF8F8FF);
  static const _accent = Color(0xFF9966CC);
  static const _dark   = Color(0xFF2D1B4E);
  static const _medium = Color(0xFF7B5EA7);
  static const _card   = Color(0xFFEDE5F8);
  static const _border = Color(0xFFD4B8E8);

  static const _verseImage = 'assets/images/verse1.jpg';
  static const _duaImage   = 'assets/images/dua1.jpg';

  static const _filters = ['All', 'Verse', 'Dua'];
  String _filterKey(String label) => label.toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedCubit>().loadSaved();
    });
  }

  // ── Open detail ───────────────────────────────────────────────────────────
  void _openDetail(BuildContext context, Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(
          arabic:    item['arabic']    ?? '',
          english:   item['english']   ?? item['translation'] ?? '',
          title:     item['title']     ?? item['prayerName']  ?? '',
          reference: item['reference'] ?? '',
          type:      item['type']      ?? 'dua',
        ),
      ),
    ).then((_) => context.read<SavedCubit>().loadSaved());
  }

  // ── Snap card back to centre ──────────────────────────────────────────────
  void _snapBack() =>
      setState(() { _dragX = 0; _dragY = 0; _isDragging = false; });

  // ── Skip to next (swipe right) ────────────────────────────────────────────
  void _goNext(List<Map<String, dynamic>> items) {
    setState(() {
      if (_currentIndex < items.length - 1) _currentIndex++;
      _dragX = 0; _dragY = 0; _isDragging = false;
    });
  }

  // ── Delete with confirm dialog ────────────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> items,
  ) async {
    _snapBack(); // snap card back while dialog is open

    final cubit   = context.read<SavedCubit>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove saved item?',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold)),
        content: Text(
          item['title'] ?? 'This item will be removed from your saved list.',
          style: TextStyle(color: _dark.withOpacity(0.6), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _medium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cubit.toggleSaved(
        type:      item['type']      ?? 'dua',
        arabic:    item['arabic']    ?? '',
        english:   item['english']   ?? item['translation'] ?? '',
        title:     item['title']     ?? '',
        reference: item['reference'] ?? '',
      );

      if (context.mounted) {
        // Stay in bounds after deletion
        setState(() {
          if (_currentIndex >= items.length - 1 && _currentIndex > 0) {
            _currentIndex--;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from saved',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Root build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: BlocBuilder<SavedCubit, SavedState>(
        builder: (context, state) {
          final count =
              state is SavedLoaded ? state.filteredItems.length : 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Collection',
                      style: TextStyle(color: _medium, fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Saved Items',
                      style: TextStyle(
                          color: _dark,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: Text(
                  '$count saved',
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return BlocBuilder<SavedCubit, SavedState>(
      builder: (context, state) {
        final currentFilter =
            state is SavedLoaded ? state.filter : 'all';
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: _filters.map((label) {
              final key      = _filterKey(label);
              final selected = currentFilter == key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    context.read<SavedCubit>().changeFilter(key);
                    setState(() {
                      _currentIndex = 0;
                      _dragX = 0;
                      _dragY = 0;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _accent : _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? _accent : _border),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : _medium,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return BlocBuilder<SavedCubit, SavedState>(
      builder: (context, state) {
        if (state is SavedLoading || state is SavedInitial) {
          return const Center(
              child: CircularProgressIndicator(color: _accent));
        }
        if (state is SavedError) {
          return Center(
            child: Text(state.message,
                style: TextStyle(color: _dark.withOpacity(0.4))),
          );
        }
        if (state is SavedLoaded) {
          final items = state.filteredItems;
          if (items.isEmpty) return _buildEmpty();

          // Keep _currentIndex in bounds
          if (_currentIndex >= items.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _currentIndex = items.length - 1);
              }
            });
          }
          return _buildCardDeck(context, items);
        }
        return const SizedBox();
      },
    );
  }

  // ── Card Deck ─────────────────────────────────────────────────────────────
  Widget _buildCardDeck(
      BuildContext context, List<Map<String, dynamic>> items) {
    final safeIdx      = _currentIndex.clamp(0, items.length - 1);
    final remaining    = items.length - safeIdx;
    final visibleCount = min(3, remaining);
    final dragProgress = (_dragX.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return Column(
      children: [
        // ── Hint ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_rounded,
                  size: 14, color: _dark.withOpacity(0.3)),
              const SizedBox(width: 6),
              Text(
                'Swipe right to skip  •  Swipe left to remove',
                style: TextStyle(
                    color: _dark.withOpacity(0.3), fontSize: 11),
              ),
            ],
          ),
        ),

        // ── Stacked cards area ────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Render from back → front so the top card is on top
                for (int i = visibleCount - 1; i > 0; i--)
                  Positioned.fill(
                    child: _buildBackCard(
                      items[safeIdx + i], i, dragProgress),
                  ),
                Positioned.fill(
                  child: _buildTopCard(
                      context, items, items[safeIdx], safeIdx),
                ),
              ],
            ),
          ),
        ),

        // ── Progress dots ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  i == safeIdx ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == safeIdx
                      ? _accent
                      : _dark.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Back card (non-interactive, peeks behind top card) ────────────────────
  Widget _buildBackCard(
      Map<String, dynamic> item, int stackIndex, double dragProgress) {
    // stackIndex 1 = directly behind top, 2 = further back
    final baseScale   = 1.0 - stackIndex * 0.06;
    final scale       = baseScale + (1.0 - baseScale) * dragProgress;
    final baseOffsetY = stackIndex * 18.0;
    final offsetY     = baseOffsetY * (1.0 - dragProgress);
    final isVerse     = item['type'] == 'verse';

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: _SavedCard(
          item:      item,
          isVerse:   isVerse,
          bgImage:   isVerse ? _verseImage : _duaImage,
          isFocused: false,
        ),
      ),
    );
  }

  // ── Top card (interactive) ────────────────────────────────────────────────
  Widget _buildTopCard(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> item,
    int safeIdx,
  ) {
    final isVerse        = item['type'] == 'verse';
    final angle          = _dragX * 0.0007; // subtle tilt
    final leftProgress   = ((-_dragX) / _swipeThreshold).clamp(0.0, 1.0);
    final rightProgress  = (_dragX / _swipeThreshold).clamp(0.0, 1.0);
    final isSwipingLeft  = _dragX < -(_swipeThreshold * 0.35);
    final isSwipingRight = _dragX > (_swipeThreshold * 0.35);

    // Build the transform matrix
    final cardTransform = Matrix4.identity()
      ..translate(_dragX, _dragY)
      ..rotateZ(angle);

    return GestureDetector(
      onTap: () => _openDetail(context, item),
      onHorizontalDragStart: (_) =>
          setState(() => _isDragging = true),
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dragX += d.delta.dx;
          _dragY += d.delta.dy * 0.25;
        });
      },
      onHorizontalDragEnd: (d) {
        final vel = d.primaryVelocity ?? 0;
        if (_dragX < -_swipeThreshold || vel < -600) {
          _confirmDelete(context, item, items);
        } else if (_dragX > _swipeThreshold || vel > 600) {
          _goNext(items);
        } else {
          _snapBack();
        }
      },
      child: AnimatedContainer(
        // Instant while dragging, smooth spring-back on release
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        transform: cardTransform,
        transformAlignment: Alignment.center,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Base card ──────────────────────────────────────────────
            _SavedCard(
              item:      item,
              isVerse:   isVerse,
              bgImage:   isVerse ? _verseImage : _duaImage,
              isFocused: true,
            ),

            // ── Delete overlay (swipe left) ────────────────────────────
            if (isSwipingLeft)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.transparent,
                          Colors.red.shade500
                              .withOpacity(leftProgress * 0.75),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: leftProgress,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            leftProgress > 0.85
                                ? Icons.delete_rounded
                                : Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            leftProgress > 0.85 ? 'RELEASE!' : 'REMOVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Next overlay (swipe right) ─────────────────────────────
            if (isSwipingRight)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          _accent.withOpacity(rightProgress * 0.65),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: rightProgress,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rightProgress > 0.85
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_outlined,
                            color: Colors.white,
                            size: 56,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rightProgress > 0.85 ? 'NEXT!' : 'SKIP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_outline_rounded,
              size: 72, color: _dark.withOpacity(0.12)),
          const SizedBox(height: 16),
          Text('Nothing saved yet',
              style: TextStyle(
                  color: _dark.withOpacity(0.4), fontSize: 17)),
          const SizedBox(height: 8),
          Text(
            'Save verses and duas from Results\nto find them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _dark.withOpacity(0.28),
                fontSize: 13,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual saved card — same style as ResultScreen's _ContentCard
// ─────────────────────────────────────────────────────────────────────────────
class _SavedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isVerse;
  final String bgImage;
  final bool isFocused;

  const _SavedCard({
    required this.item,
    required this.isVerse,
    required this.bgImage,
    required this.isFocused,
  });

  static const _dark   = Color(0xFF2D1B4E);
  static const _accent = Color(0xFF9966CC);

  @override
  Widget build(BuildContext context) {
    final arabic  = item['arabic']               ?? '';
    final english = item['english']
        ?? item['translation']                   ?? '';
    final title   = item['title']                ?? '';
    final ref     = item['reference']            ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isFocused ? 0.18 : 0.07),
            blurRadius:   isFocused ? 28 : 14,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ────────────────────────────────────────
            Image.asset(bgImage, fit: BoxFit.cover),

            // ── Frosted glass overlay ───────────────────────────────────
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: Container(
                  color: Colors.white.withOpacity(0.30)),
            ),

            // ── Content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Type chip + title ──────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:  _accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _accent.withOpacity(0.35)),
                        ),
                        child: Text(
                          isVerse ? '📖 Verse' : '🤲 Dua',
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                              color: _dark.withOpacity(0.5),
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // ── Arabic + translation ────────────────────────────────
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              arabic,
                              textAlign:     TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  color:      Colors.black,
                                  fontSize:   22,
                                  fontWeight: FontWeight.bold,
                                  height:     1.85),
                            ),
                            const SizedBox(height: 18),
                            // Gradient divider
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  _accent.withOpacity(0.5),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '"$english"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:     Colors.black.withOpacity(0.75),
                                  fontSize:  13,
                                  fontStyle: FontStyle.italic,
                                  height:    1.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Reference + tap hint ───────────────────────────────
                  Column(
                    children: [
                      if (ref.isNotEmpty)
                        Text(
                          ref,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color:      Colors.black.withOpacity(0.45),
                              fontSize:   11,
                              fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 12,
                              color: Colors.black.withOpacity(0.3)),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                                color:    Colors.black.withOpacity(0.3),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
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
