// lib/cubit/mood_state.dart
//
// Represents every possible UI state for the Mood History screen.
// Cubit emits one of these sealed subclasses; the BlocBuilder reacts to each.

abstract class MoodState {}

/// Initial state before any data has been requested.
class MoodInitial extends MoodState {}

/// Shown while the SQLite query is running.
class MoodLoading extends MoodState {}

/// Shown when data has been successfully retrieved (may be an empty list).
class MoodLoaded extends MoodState {
  final List<Map<String, dynamic>> moods;
  final int selectedPeriod; // 0 = Today, 1 = This Week

  MoodLoaded({required this.moods, required this.selectedPeriod});
}

/// Shown if the database throws an unexpected error.
class MoodError extends MoodState {
  final String message;
  MoodError(this.message);
}