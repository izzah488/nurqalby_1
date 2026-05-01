// lib/cubit/mood_cubit.dart
//
// Handles all business logic for the Mood History feature.
// Calls MoodDatabase and emits the correct MoodState.
// The UI (MoodHistoryScreen) only calls methods here — it never touches
// the database directly.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'mood_state.dart';
import '../services/mood_database.dart';

class MoodCubit extends Cubit<MoodState> {
  MoodCubit() : super(MoodInitial());

  /// Call this when the screen first opens, or when the user switches the
  /// Today / This Week toggle.
  ///
  /// [period] — 0 = Today, 1 = This Week
  Future<void> loadMoods(int period) async {
    emit(MoodLoading());
    try {
      final data = period == 0
          ? await MoodDatabase.instance.getDailyMoods()
          : await MoodDatabase.instance.getWeeklyMoods();

      emit(MoodLoaded(moods: data, selectedPeriod: period));
    } catch (e) {
      emit(MoodError('Failed to load mood history: $e'));
    }
  }

  /// Call after a new mood session is saved so the screen refreshes
  /// automatically without the user having to restart the app.
  Future<void> refresh() async {
    // Keep the currently selected period if we already have a loaded state.
    final currentPeriod =
        (state is MoodLoaded) ? (state as MoodLoaded).selectedPeriod : 1;
    await loadMoods(currentPeriod);
  }
}