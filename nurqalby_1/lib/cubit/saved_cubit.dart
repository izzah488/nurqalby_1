// lib/cubit/saved_cubit.dart
//
// Manages the Saved Items feature (SharedPreferences-backed bookmark store).
// The UI never reads SharedPreferences directly — it only calls methods here.

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saved_state.dart';

class SavedCubit extends Cubit<SavedState> {
  SavedCubit() : super(SavedInitial());

  String _currentFilter = 'all';

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadSaved() async {
    emit(SavedLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('saved_items') ?? [];
      final items = raw
          .map((s) => Map<String, dynamic>.from(jsonDecode(s)))
          .toList()
          .reversed
          .toList(); // newest first

      emit(SavedLoaded(items: items, filter: _currentFilter));
    } catch (e) {
      emit(SavedError('Could not load saved items: $e'));
    }
  }

  // ── Filter ──────────────────────────────────────────────────────────────────

  void changeFilter(String filter) {
    _currentFilter = filter;
    if (state is SavedLoaded) {
      final loaded = state as SavedLoaded;
      emit(SavedLoaded(items: loaded.items, filter: filter));
    }
  }

  // ── Toggle Save/Unsave ──────────────────────────────────────────────────────

  /// Adds or removes an item.  Call this from ANY screen (ResultScreen,
  /// DoaDetailScreen, NotificationDetailScreen) to keep the saved list in sync.
  Future<void> toggleSaved({
    required String type,       // 'verse' or 'dua'
    required String arabic,
    required String english,
    required String title,
    required String reference,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getStringList('saved_items') ?? [];
      final key   = '${type}_$arabic';

      final exists = raw.any((s) {
        final map = jsonDecode(s);
        return map['key'] == key;
      });

      if (exists) {
        raw.removeWhere((s) {
          final map = jsonDecode(s);
          return map['key'] == key;
        });
      } else {
        raw.add(jsonEncode({
          'key':       key,
          'type':      type,
          'title':     title,
          'arabic':    arabic,
          'english':   english,
          'reference': reference,
        }));
      }

      await prefs.setStringList('saved_items', raw);
      await loadSaved(); // refresh state after change
    } catch (e) {
      emit(SavedError('Could not update saved items: $e'));
    }
  }

  // ── Delete All ──────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_items');
    emit(SavedLoaded(items: [], filter: _currentFilter));
  }
}