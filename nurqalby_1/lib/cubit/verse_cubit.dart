import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import 'verse_state.dart';

class VerseCubit extends Cubit<VerseState> {
  VerseCubit() : super(VerseInitial());

  Future<void> fetchVerses({
  required String text,
  required String emotion,
  required String cause,
}) async {
  emit(VerseLoading());
  try {
    final verses = await ApiService.recommend(
      text:    text,
      emotion: emotion,
      cause:   cause,
    );
    final duas = await ApiService.recommendDua(text: text);
    emit(VerseSuccess(verses, duas));
  } catch (e) {
    emit(VerseError(e.toString()));
  }
}
}