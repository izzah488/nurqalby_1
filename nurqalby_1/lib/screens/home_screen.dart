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

  final List<Widget> _screens = [
    const InputScreen(),
    const SavedScreen(),
    const MoodHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF3D6645), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex:        _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor:     const Color(0xFF0F1E12),
          selectedItemColor:   const Color(0xFFFFFDD0),
          unselectedItemColor: const Color(0xFFFFFDD0).withOpacity(0.35),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon:  Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon:  Icon(Icons.bookmark_outline_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon:  Icon(Icons.bar_chart_rounded),
              label: 'Mood',
            ),
          ],
        ),
      ),
    );
  }
}
