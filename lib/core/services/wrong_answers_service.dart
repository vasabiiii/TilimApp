import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wrong_answer.dart';
import '../../../features/auth/services/auth_service.dart';

class WrongAnswersService {
  static const String _baseKey = 'wrong_answers';
  final SharedPreferences _prefs;
  final AuthService _authService;

  WrongAnswersService(this._prefs, this._authService);

  Future<String> get _key async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      throw Exception('Не удалось получить ID пользователя. Возможно, вы не авторизованы.');
    }
    return '${_baseKey}_$userId';
  }

  Future<void> saveWrongAnswer(WrongAnswer wrongAnswer) async {
    try {
      final key = await _key;
      final List<String> existingAnswers = _prefs.getStringList(key) ?? [];
      final List<WrongAnswer> answers = existingAnswers
          .map((String jsonStr) => WrongAnswer.fromJson(jsonDecode(jsonStr)))
          .toList();
      
      bool isDuplicate = answers.any((answer) => 
        answer.question == wrongAnswer.question &&
        answer.correctAnswer == wrongAnswer.correctAnswer
      );
      
      if (!isDuplicate) {
        existingAnswers.add(jsonEncode(wrongAnswer.toJson()));
        await _prefs.setStringList(key, existingAnswers);
      }
    } catch (e) {
      print('Ошибка при сохранении неправильного ответа: $e');
    }
  }

  Future<List<WrongAnswer>> getWrongAnswers() async {
    try {
      final key = await _key;
      final List<String> savedAnswers = _prefs.getStringList(key) ?? [];
      return savedAnswers
          .map((String jsonStr) => WrongAnswer.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('Ошибка при получении неправильных ответов: $e');
      return [];
    }
  }

  Future<void> clearWrongAnswers() async {
    try {
      final key = await _key;
      await _prefs.remove(key);
    } catch (e) {
      print('Ошибка при очистке неправильных ответов: $e');
    }
  }
} 