import 'dart:convert';
import '../../../config/app_config.dart';
import '../../../core/services/http_service.dart';
import '../models/quiz_question_model.dart';

class LessonService {
  final HttpService _httpService = HttpService();

  Future<LessonModel?> getLesson(int lessonId) async {
    try {
      final response = await _httpService.get('${AppConfig.baseUrl}/lessons/$lessonId');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        print('Получены данные от сервера: $data');
        
        try {
          return LessonModel.fromJson(data);
        } catch (e) {
          print('Ошибка при парсинге данных: $e');
          return null;
        }
      } else {
        print('Ошибка при получении урока: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при получении урока: $e');
      return null;
    }
  }

  Future<bool> completeLesson(int lessonId) async {
    try {
      final response = await _httpService.post(
        '${AppConfig.baseUrl}/lessons/$lessonId/complete',
        body: jsonEncode({'lesson_id': lessonId}),
      );

      if (response.statusCode == 200) {
        print('Урок $lessonId успешно завершен');
        return true;
      } else {
        print('Ошибка при завершении урока: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка при завершении урока: $e');
      return false;
    }
  }
} 