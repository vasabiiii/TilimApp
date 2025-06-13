import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../../../core/services/http_service.dart';

class ProfileService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> getProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Ошибка получения профиля'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Ошибка подключения к серверу: $e'};
    }
  }

  Future<bool> updateUsername(String username) async {
    try {
      final response = await _httpService.patch(
        '${AppConfig.baseUrl}/profile/username',
        body: jsonEncode({'username': username}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Ошибка при обновлении имени пользователя: $e');
    }
  }

  Future<bool> updateEmail(String email) async {
    try {
      final response = await _httpService.patch(
        '${AppConfig.baseUrl}/profile/email',
        body: jsonEncode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Ошибка при обновлении email: $e');
    }
  }

  Future<bool> updateAvatar(String avatarPath) async {
    try {
      print('Отправка запроса на обновление аватара: $avatarPath');
      final response = await _httpService.patch(
        '${AppConfig.baseUrl}/profile/avatar',
        body: jsonEncode({'image': avatarPath}),
      );

      print('Ответ сервера: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при обновлении аватара: $e');
      throw Exception('Ошибка при обновлении аватара: $e');
    }
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _httpService.patch(
        '${AppConfig.baseUrl}/profile/password',
        body: jsonEncode({
          'password': oldPassword,
          'new_password': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Ошибка при обновлении пароля: $e');
    }
  }
} 