abstract class VerseState {}

class VerseInitial extends VerseState {}
class VerseLoading extends VerseState {}

class VerseSuccess extends VerseState {
  final List<Map<String, dynamic>> verses;
  final List<Map<String, dynamic>> duas;    // ← change String to dynamic
  VerseSuccess(this.verses, this.duas);
}

class VerseError extends VerseState {
  final String message;
  VerseError(this.message);
}