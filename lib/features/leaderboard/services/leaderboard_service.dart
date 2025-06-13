import 'dart:convert';
import '../../../core/services/http_service.dart';
import '../models/leaderboard_model.dart';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';

class LeaderboardService {
  final String baseUrl = 'http://localhost:8080';
  final HttpService _httpService = HttpService();

  Future<List<LeaderboardEntry>> getLeaderboard(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Требуется заголовок c access token');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/leaderboards'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return (decoded as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Ошибка загрузки лидерборда');
    }
  }

  Future<List<LeaderboardEntry>> searchPlayers(String query, String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Требуется заголовок c access token');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/leaderboards/search?q=${Uri.encodeComponent(query)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return (decoded as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Ошибка поиска игроков');
    }
  }

  List<LeaderboardEntry> filterByLeague(List<LeaderboardEntry> entries, League? league) {
    if (league == null) return entries;
    return entries.where((entry) => entry.league == league).toList();
  }

  Map<League, List<LeaderboardEntry>> groupByLeague(List<LeaderboardEntry> entries) {
    final Map<League, List<LeaderboardEntry>> grouped = {};
    
    for (final league in League.values) {
      grouped[league] = entries.where((entry) => entry.league == league).toList();
    }
    
    return grouped;
  }
} 