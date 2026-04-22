import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'saved_screen.dart';
import 'mood_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ✅ FIXED: added MoodHistoryScreen as 3rd tab
  final List<Widget> _screens = [
    const InputScreen(),
    const SavedScreen(),
    const MoodHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:        _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor:     const Color(0xFF0d2016),
        selectedItemColor:   const Color(0xFF4CAF50),
        unselectedItemColor: Colors.white.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon:  Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon:  Icon(Icons.bookmark_outline_rounded),
            label: 'Saved',
          ),
          // ✅ FIXED: IconButton moved here as a proper BottomNavigationBarItem
          BottomNavigationBarItem(
            icon:  Icon(Icons.bar_chart_rounded),
            label: 'Mood',
          ),
        ],
      ),
    );
  }
}
