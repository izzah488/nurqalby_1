import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'saved_screen.dart';

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
        ],
      ),
    );
  }
}