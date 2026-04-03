abstract class VerseState {}

class VerseInitial  extends VerseState {}
class VerseLoading  extends VerseState {}
class VerseSuccess  extends VerseState {
  final List<Map<String, dynamic>> verses;
  VerseSuccess(this.verses);
}
class VerseError    extends VerseState {
  final String message;
  VerseError(this.message);
}