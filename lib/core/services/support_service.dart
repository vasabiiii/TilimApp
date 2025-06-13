import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/support_message.dart';
import 'telegram_service.dart';

class SupportService {
  static const String _key = 'support_messages';

  Future<void> saveMessage(SupportMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingMessages = prefs.getStringList(_key) ?? [];
    
    existingMessages.add(jsonEncode(message.toJson()));
    
    await prefs.setStringList(_key, existingMessages);
  }

  Future<List<SupportMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedMessages = prefs.getStringList(_key) ?? [];
    
    return savedMessages
        .map((String jsonStr) => SupportMessage.fromJson(jsonDecode(jsonStr)))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Новые сверху
  }

  Future<void> updateMessageWithReply(String messageId, String reply) async {
    final messages = await getMessages();
    final updatedMessages = messages.map((message) {
      if (message.id == messageId) {
        return message.copyWith(
          reply: reply,
          replyTimestamp: DateTime.now(),
          status: 'answered',
        );
      }
      return message;
    }).toList();

    await _saveAllMessages(updatedMessages);
  }

  Future<int> checkForNewReplies() async {
    try {
      final replies = await TelegramService.checkReplies();
      int newRepliesCount = 0;

      for (var reply in replies) {
        final messageId = reply['messageId'];
        final replyText = reply['reply'];
        
  
        final messages = await getMessages();
        final existingMessage = messages.firstWhere(
          (msg) => msg.id == messageId,
          orElse: () => SupportMessage(
            id: '',
            message: '',
            email: '',
            timestamp: DateTime.now(),
          ),
        );

        if (existingMessage.id.isNotEmpty && existingMessage.reply == null) {
          await updateMessageWithReply(messageId, replyText);
          newRepliesCount++;
        }
      }

      return newRepliesCount;
    } catch (e) {
      print('Ошибка проверки ответов: $e');
      return 0;
    }
  }

  Future<void> _saveAllMessages(List<SupportMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonMessages = messages
        .map((message) => jsonEncode(message.toJson()))
        .toList();
    
    await prefs.setStringList(_key, jsonMessages);
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
} 