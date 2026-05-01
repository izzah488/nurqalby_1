// lib/screens/notification_history_screen.dart
//
// FIXED:
// 1. History entries saved by notification_service.dart include future
//    scheduled items. We show ALL of them (past + upcoming) so user
//    can see what's coming — with a clear time label.
// 2. "Older" group logic was wrong — fixed to show multi-day history.
// 3. Tapping an item marks it read AND opens NotificationDetailScreen.

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

  // Toggle: show only past or all (including upcoming scheduled)
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('notification_history') ?? [];

    final parsed = list
        .map((s) {
          try {
            return Map<String, dynamic>.from(jsonDecode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    // Sort newest first
    parsed.sort((a, b) {
      final ta = DateTime.tryParse(a['time'] ?? '') ?? DateTime(2000);
      final tb = DateTime.tryParse(b['time'] ?? '') ?? DateTime(2000);
      return tb.compareTo(ta);
    });

    setState(() {
      history   = parsed;
      isLoading = false;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep newest-first order in storage too
    await prefs.setStringList(
        'notification_history', history.map((e) => jsonEncode(e)).toList());
  }

  void _deleteItem(int index) {
    setState(() => history.removeAt(index));
    _saveHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:  Text('Notification deleted'),
          duration: Duration(seconds: 1)),
    );
  }

  void _toggleRead(int index) {
    setState(() {
      history[index]['isRead'] = !(history[index]['isRead'] ?? false);
    });
    _saveHistory();
  }

  // FIXED: Correct grouping logic that works across multiple days
  Map<String, List<Map<String, dynamic>>> _groupHistory() {
    final groups = <String, List<Map<String, dynamic>>>{
      'Today':      [],
      'Yesterday':  [],
      'This Week':  [],
      'Upcoming':   [],
      'Older':      [],
    };

    final now       = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (final item in history) {
      final dt   = DateTime.tryParse(item['time'] ?? '');
      if (dt == null) continue;

      final itemDate = DateTime(dt.year, dt.month, dt.day);
      final diffDays = itemDate.difference(todayDate).inDays;

      if (dt.isAfter(now)) {
        groups['Upcoming']!.add(item);
      } else if (diffDays == 0) {
        groups['Today']!.add(item);
      } else if (diffDays == -1) {
        groups['Yesterday']!.add(item);
      } else if (diffDays >= -7) {
        groups['This Week']!.add(item);
      } else {
        groups['Older']!.add(item);
      }
    }

    // Show/hide upcoming based on toggle; remove empty groups
    if (!_showAll) groups.remove('Upcoming');
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  String _formatTime(String isoString) {
    final dt  = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final now  = DateTime.now();
    final diff = dt.difference(now);

    if (diff.isNegative) {
      final past = now.difference(dt);
      if (past.inMinutes < 1)  return 'Just now';
      if (past.inMinutes < 60) return '${past.inMinutes}m ago';
      if (past.inHours   < 24) return '${past.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } else {
      // Upcoming
      if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
      if (diff.inHours   < 24) return 'in ${diff.inHours}h';
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupHistory();
    final groupKeys   = groupedData.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
                top: 60, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9966CC), Color(0xFFB388EB)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:      const Color(0xFF9966CC).withOpacity(0.3),
                  blurRadius: 15,
                  offset:     const Offset(0, 5),
                )
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft:  Radius.circular(30),
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
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'History',
                  style: TextStyle(
                      color:      Colors.white,
                      fontSize:   22,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Toggle upcoming
                GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showAll ? 'Hide upcoming' : 'Show upcoming',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.white),
                    onPressed: () {
                      setState(() => history.clear());
                      _saveHistory();
                    },
                  ),
                ]
              ],
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF9966CC)))
                : history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemCount: groupKeys.length,
                        itemBuilder: (context, gIndex) {
                          final groupName = groupKeys[gIndex];
                          final items     = groupedData[groupName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 8, 24, 12),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    color: const Color(0xFF2D1B4E)
                                        .withOpacity(0.6),
                                    fontWeight:    FontWeight.bold,
                                    fontSize:      13,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              ...items.map((item) {
                                final idx = history.indexOf(item);
                                return _buildCard(item, idx);
                              }),
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

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final bool isRead     = item['isRead'] ?? false;
    final bool isUpcoming = DateTime.tryParse(item['time'] ?? '')
            ?.isAfter(DateTime.now()) ??
        false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key('${item['time']}_$index'),
        direction: DismissDirection.horizontal,
        background: _swipeBackground(
            Icons.mark_email_read, Colors.blue, Alignment.centerLeft),
        secondaryBackground: _swipeBackground(
            Icons.delete_outline, Colors.red, Alignment.centerRight),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) _deleteItem(index);
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _toggleRead(index);
            return false;
          }
          return true;
        },
        child: GestureDetector(
          onTap: () {
            if (!isRead && !isUpcoming) _toggleRead(index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                  arabic:    item['arabic']    ?? '',
                  english:   item['english']   ?? '',
                  title:     item['title']     ?? 'Notification',
                  reference: item['reference'] ?? '',
                  type:      item['type']      ?? 'dua',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.white.withOpacity(0.7)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isUpcoming
                  ? Border.all(
                      color: const Color(0xFF9966CC).withOpacity(0.3))
                  : null,
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                  blurRadius: 10,
                  offset:     const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? const Color(0xFFF3E5F5)
                        : (item['type'] == 'verse'
                            ? const Color(0xFFEDE5F8)
                            : const Color(0xFFE8F5E9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUpcoming
                        ? Icons.schedule_rounded
                        : (item['type'] == 'verse'
                            ? Icons.auto_stories
                            : Icons.favorite),
                    color: isUpcoming
                        ? const Color(0xFF9966CC).withOpacity(0.6)
                        : (item['type'] == 'verse'
                            ? const Color(0xFF9966CC)
                            : Colors.green),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Text
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
                                fontWeight: isRead && !isUpcoming
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 15,
                                color: isRead && !isUpcoming
                                    ? const Color(0xFF2D1B4E).withOpacity(0.5)
                                    : const Color(0xFF2D1B4E),
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item['time'] ?? ''),
                            style: TextStyle(
                              color: isUpcoming
                                  ? const Color(0xFF9966CC).withOpacity(0.7)
                                  : const Color(0xFF2D1B4E).withOpacity(0.4),
                              fontSize:   11,
                              fontWeight: isUpcoming
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['english'] ?? '',
                        style: TextStyle(
                          color: const Color(0xFF2D1B4E)
                              .withOpacity(isRead ? 0.3 : 0.6),
                          fontSize: 13,
                          height:   1.3,
                        ),
                        maxLines:  2,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread dot
                if (!isRead && !isUpcoming)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width:  8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9966CC),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground(
      IconData icon, Color color, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      alignment: alignment,
      decoration: BoxDecoration(
        color:        color,
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
          Icon(Icons.notifications_none_outlined,
              size:  80,
              color: const Color(0xFF2D1B4E).withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                color:    const Color(0xFF2D1B4E).withOpacity(0.4),
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}