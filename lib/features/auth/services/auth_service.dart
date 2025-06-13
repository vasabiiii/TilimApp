import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  Future<bool> signIn(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tokens'] != null) {
          await _saveTokens(
            accessToken: data['tokens']['access_token'],
            refreshToken: data['tokens']['refresh_token'],
          );
          if (data['user_id'] != null) {
            await _saveUserId(data['user_id']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      print('register: Отправка запроса на регистрацию');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'phone_number': phoneNumber,
        }),
      );

      print('register: Получен ответ: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['tokens'] != null) {
          await _saveTokens(
            accessToken: data['tokens']['access_token'],
            refreshToken: data['tokens']['refresh_token'],
          );
          print('register: Токены сохранены');
        }
        
        if (data['user_id'] != null) {
          await _saveUserId(data['user_id']);
          print('register: ID пользователя сохранен: ${data['user_id']}');
        }
        
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['message'] ?? 'Ошибка регистрации'};
      }
    } catch (e) {
      print('register: Ошибка при регистрации: $e');
      return {'success': false, 'error': 'Ошибка подключения к серверу: $e'};
    }
  }

  Future<void> _saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> logout() async {
    print('logout: Начало выхода из системы');
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    
    print('logout: Все данные удалены');
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'error': 'Требуется авторизация'};
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': false, 'error': error['message'] ?? 'Ошибка получения профиля'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Ошибка подключения к серверу: $e'};
    }
  }

  Future<String?> getCurrentUserId() async {
    final userId = await getUserId();
    if (userId == null) return null;
    return userId.toString();
  }
} 