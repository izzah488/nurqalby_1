// lib/screens/home_screen.dart
//
// UPDATED: Provides MoodCubit and SavedCubit at the top level so they are
// shared across all bottom-nav tabs without re-creating on tab switch.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/mood_cubit.dart';
import '../cubit/saved_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Cubits are created ONCE here and survive tab switching.
      // Any child widget can call context.read<MoodCubit>() etc.
      providers: [
        BlocProvider(create: (_) => MoodCubit()..loadMoods(1)),
        BlocProvider(create: (_) => SavedCubit()..loadSaved()),
      ],
      child: Scaffold(
        body: IndexedStack(
          // IndexedStack keeps all screens alive — mood data is not re-fetched
          // every time the user switches tabs.
          index: _currentIndex,
          children: const [
            InputScreen(),
            SavedScreen(),
            MoodHistoryScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFD4B8E8), width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex:        _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor:     const Color(0xFFF8F8FF),
            selectedItemColor:   const Color(0xFF2D1B4E),
            unselectedItemColor: const Color(0xFF2D1B4E).withOpacity(0.35),
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(
                  icon:       Icon(Icons.bookmark_outline_rounded),
                  activeIcon: Icon(Icons.bookmark_rounded),
                  label:      'Saved'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded), label: 'Mood'),
            ],
          ),
        ),
      ),
    );
  }
}