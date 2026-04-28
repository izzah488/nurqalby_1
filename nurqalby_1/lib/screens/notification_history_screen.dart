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
    final list = prefs.getStringList('notification_history') ?? [];
    final now = DateTime.now();

    setState(() {
      history = list
          .map((s) => Map<String, dynamic>.from(jsonDecode(s)))
          .where((map) => DateTime.parse(map['time']).isBefore(now))
          .toList()
          .reversed
          .toList();
      isLoading = false;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = history.map((e) => jsonEncode(e)).toList().reversed.toList();
    await prefs.setStringList('notification_history', list);
  }

  void _deleteItem(int index, Map<String, dynamic> item) {
    setState(() {
      history.removeAt(index);
    });
    _saveHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification deleted"), duration: Duration(seconds: 1)),
    );
  }

  void _toggleRead(int index) {
    setState(() {
      history[index]['isRead'] = !(history[index]['isRead'] ?? false);
    });
    _saveHistory();
  }

  Map<String, List<Map<String, dynamic>>> _groupHistory() {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: now.weekday));

    for (var item in history) {
      final date = DateTime.parse(item['time']);
      final compareDate = DateTime(date.year, date.month, date.day);

      if (compareDate == today) {
        groups['Today']!.add(item);
      } else if (compareDate == yesterday) {
        groups['Yesterday']!.add(item);
      } else if (compareDate.isAfter(thisWeek)) {
        groups['This Week']!.add(item);
      } else {
        groups['Older']!.add(item);
      }
    }
    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  String _formatTime(String isoString) {
    final dt = DateTime.parse(isoString);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupHistory();
    final groupKeys = groupedData.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      body: Column(
        children: [
          // 2.1 Premium Gradient Header
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9966CC), Color(0xFFB388EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9966CC).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "History",
                  style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                    onPressed: () {
                      setState(() => history.clear());
                      _saveHistory();
                    },
                  )
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9966CC)))
                : history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemCount: groupKeys.length,
                        itemBuilder: (context, gIndex) {
                          final groupName = groupKeys[gIndex];
                          final items = groupedData[groupName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    color: const Color(0xFF2D1B4E).withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              ...items.map((item) {
                                final originalIndex = history.indexOf(item);
                                return _buildNotificationCard(item, originalIndex);
                              }).toList(),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final bool isRead = item['isRead'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(item['time'] + index.toString()),
        direction: DismissDirection.horizontal,
        background: _swipeActionBackground(Icons.mark_email_read, Colors.blue, Alignment.centerLeft),
        secondaryBackground: _swipeActionBackground(Icons.delete_outline, Colors.red, Alignment.centerRight),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteItem(index, item);
          }
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _toggleRead(index);
            return false; // Don't actually remove the widget
          }
          return true;
        },
        child: GestureDetector(
          onTap: () {
            if (!isRead) _toggleRead(index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                  arabic: item['arabic'] ?? '',
                  english: item['english'] ?? '',
                  title: item['title'] ?? 'Notification',
                  reference: item['reference'] ?? '',
                  type: item['type'] ?? 'verse',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead ? Colors.white.withOpacity(0.7) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              // 2.2 Modern Shadow and Style
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['type'] == 'verse' ? const Color(0xFFEDE5F8) : const Color(0xFFE8F5E9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['type'] == 'verse' ? Icons.auto_stories : Icons.favorite,
                    color: item['type'] == 'verse' ? const Color(0xFF9966CC) : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] ?? 'Islamic Reminder',
                              style: TextStyle(
                                // 1.4 Unread Bold/Brighter logic
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 15,
                                color: isRead ? const Color(0xFF2D1B4E).withOpacity(0.5) : const Color(0xFF2D1B4E),
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item['time'] ?? ''),
                            style: TextStyle(
                              color: const Color(0xFF2D1B4E).withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['english'] ?? '',
                        style: TextStyle(
                          color: const Color(0xFF2D1B4E).withOpacity(isRead ? 0.3 : 0.6),
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9966CC),
                      shape: BoxShape.circle,
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeActionBackground(IconData icon, Color color, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: const Color(0xFF2D1B4E).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(color: const Color(0xFF2D1B4E).withOpacity(0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }
}