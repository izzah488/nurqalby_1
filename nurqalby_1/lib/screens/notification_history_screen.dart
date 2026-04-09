import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'notification_detail_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('notification_history') ?? [];
    setState(() {
      history = list
          .map((s) => Map<String, dynamic>.from(jsonDecode(s)))
          .toList()
          .reversed
          .toList();
      isLoading = false;
    });
  }

  String _formatTime(String isoString) {
    final dt  = DateTime.parse(isoString);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
                      Text('Your Reminders',
                          style: TextStyle(
                              color: Color(0xFF9fd4b0),
                              fontSize: 12)),
                      Text('Notification History',
                          style: TextStyle(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50)))
                  : history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size:  64,
                                  color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No notifications yet',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.4),
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NotificationDetailScreen(
                                    arabic:    item['arabic'] ?? '',
                                    english:   item['english'] ?? '',
                                    title:     item['title'] ?? '',
                                    reference: item['reference'] ?? '',
                                    type:      item['type'] ?? 'dua',
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF142d1e),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          const Color(0xFF2d5a3d)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width:  44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFF1a3a2a),
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_rounded,
                                        color: Color(0xFF4CAF50),
                                        size:  22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(
                                                color:      Colors.white,
                                                fontSize:   13,
                                                fontWeight:
                                                    FontWeight.w500),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['english'] ?? '',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                                fontSize: 11),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(
                                          item['time'] ?? ''),
                                      style: TextStyle(
                                          color: Colors.white
                                              .withOpacity(0.3),
                                          fontSize: 11),
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