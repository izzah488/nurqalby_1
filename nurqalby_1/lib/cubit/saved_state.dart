// lib/cubit/saved_state.dart
//
// Represents every possible UI state for the Saved Screen.

abstract class SavedState {}

class SavedInitial extends SavedState {}

class SavedLoading extends SavedState {}

class SavedLoaded extends SavedState {
  final List<Map<String, dynamic>> items;
  final String filter; // 'all', 'verse', 'dua'

  SavedLoaded({required this.items, required this.filter});

  /// Returns only items that match the active filter.
  List<Map<String, dynamic>> get filteredItems {
    if (filter == 'all') return items;
    return items.where((i) => i['type'] == filter).toList();
  }
}

class SavedError extends SavedState {
  final String message;
  SavedError(this.message);
}