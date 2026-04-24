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
                                  color:
                                      const Color(0xFF2D1B4E).withOpacity(0.15)),
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

                            return GestureDetector(
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
                              child: _SavedCard(
                                item: item,
                                isVerse: isVerse,
                                onRemove: () => _removeItem(index),
                              ),
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

// ── Shared card widget — same style for both Verse and Dua ─────────────────
class _SavedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isVerse;
  final VoidCallback onRemove;

  const _SavedCard({
    required this.item,
    required this.isVerse,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5F8),          // ← same for both
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4B8E8)), // ← same for both
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Coloured top accent bar (verse = amethyst, dua = teal-purple) ──
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isVerse
                  ? const Color(0xFF9966CC)       // amethyst for verse
                  : const Color(0xFF7B5EA7),       // medium purple for dua
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Badge row ───────────────────────────────────────────────
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
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        Icons.bookmark_remove_rounded,
                        color: const Color(0xFF2D1B4E).withOpacity(0.3),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                      color: Color(0xFF7B5EA7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),

                // ── Arabic ───────────────────────────────────────────────────
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

                // ── English ──────────────────────────────────────────────────
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

                // ── Reference + time ─────────────────────────────────────────
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
