import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../../features/auth/services/auth_service.dart';

class ChatHistoryService {
  static const String _baseKey = 'chat_history';
  final SharedPreferences _prefs;
  final AuthService _authService;

  ChatHistoryService(this._prefs, this._authService);

  Future<String> get _key async {
    final userId = await _authService.getCurrentUserId();
    return '${_baseKey}_${userId ?? 'anonymous'}';
  }

  Future<void> saveMessage(ChatMessage message) async {
    final key = await _key;
    final List<String> existingMessages = _prefs.getStringList(key) ?? [];
    final List<ChatMessage> messages = existingMessages
        .map((String jsonStr) => ChatMessage.fromJson(jsonDecode(jsonStr)))
        .toList();
    
    messages.add(message);
    
    if (messages.length > 50) {
      messages.removeRange(0, messages.length - 50);
    }
    
    final updatedMessages = messages
        .map((message) => jsonEncode(message.toJson()))
        .toList();
    
    await _prefs.setStringList(key, updatedMessages);
  }

  Future<List<ChatMessage>> getMessages() async {
    final key = await _key;
    final List<String> savedMessages = _prefs.getStringList(key) ?? [];
    return savedMessages
        .map((String jsonStr) => ChatMessage.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  Future<void> clearHistory() async {
    final key = await _key;
    await _prefs.remove(key);
  }
} 