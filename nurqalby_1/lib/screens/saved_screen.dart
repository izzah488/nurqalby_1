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
    final key   = savedItems[index]['key'];
    saved.removeWhere((s) {
      final map = jsonDecode(s);
      return map['key'] == key;
    });
    await prefs.setStringList('saved_items', saved);
    setState(() => savedItems.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:         Text('Removed from saved'),
        backgroundColor: Color(0xFF1a3a2a),
        duration:        Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d2016),
      body: SafeArea(
        child: Column(
          children: [

            // Header
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color:   const Color(0xFF1a3a2a),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Collection',
                      style: TextStyle(
                          color: Color(0xFF9fd4b0), fontSize: 12)),
                  Text('Saved Items',
                      style: TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50)))
                  : savedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bookmark_outline_rounded,
                                  size:  64,
                                  color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No saved items yet',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.4),
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                'Save verses and duas to find them here',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: savedItems.length,
                          itemBuilder: (context, index) {
                            final item  = savedItems[index];
                            final isVerse = item['type'] == 'verse';
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NotificationDetailScreen(
                                    arabic:    item['arabic'],
                                    english:   item['english'],
                                    title:     item['title'],
                                    reference: item['reference'],
                                    type:      item['type'],
                                  ),
                                ),
                              ).then((_) => _loadSaved()),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isVerse
                                      ? const Color(0xFF142d1e)
                                      : const Color(0xFF1e1428),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isVerse
                                        ? const Color(0xFF2d5a3d)
                                        : const Color(0xFF3d2d5a),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    // Type badge + delete
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isVerse
                                                ? const Color(
                                                    0xFF1a3a2a)
                                                : const Color(
                                                    0xFF2a1a3a),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                          ),
                                          child: Text(
                                            isVerse
                                                ? '📖 Verse'
                                                : '🤲 Dua',
                                            style: TextStyle(
                                                color: isVerse
                                                    ? const Color(
                                                        0xFF9fd4b0)
                                                    : const Color(
                                                        0xFFd4b8f0),
                                                fontSize: 11),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              _removeItem(index),
                                          child: Icon(
                                            Icons.bookmark_remove_rounded,
                                            color: Colors.white
                                                .withOpacity(0.3),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      item['title'] ?? '',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.6),
                                          fontSize:  12,
                                          fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(height: 8),

                                    // Arabic
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        item['arabic'] ?? '',
                                        style: const TextStyle(
                                            color:      Colors.white,
                                            fontSize:   16,
                                            fontWeight: FontWeight.w600,
                                            height:     1.6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // English
                                    Text(
                                      item['english'] ?? '',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                          height:   1.4),
                                      maxLines:  2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
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