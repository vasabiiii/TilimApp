import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  static const String _botToken = '8195487056:AAFrlA9V_ZGGEeLae6h98129TeQvdJej2ts';
  static const String _chatId = '-4818894189'; // ID группы
  
  static Future<Map<String, dynamic>> sendMessage({
    required String username,
    required String email,
    required String message,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch;
      
      final telegramMessage = '''
🔔 *Новое обращение #$messageId*

👤 *Пользователь:* $username
📧 *Email:* $email

💬 *Сообщение:*
$message

⏰ *Время:* ${DateTime.now().toString().substring(0, 19)}

💡 *Для ответа напишите:*
`/reply $messageId Ваш ответ`
      ''';

      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_id': _chatId,
          'text': telegramMessage,
          'parse_mode': 'Markdown',
        }),
      );

      print('Telegram response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageId': messageId,
        };
      } else {
        return {'success': false, 'error': 'Ошибка отправки'};
      }
    } catch (e) {
      print('Ошибка отправки в Telegram: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> checkReplies() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.telegram.org/bot$_botToken/getUpdates?offset=-1&limit=100'),
      );

      print('getUpdates response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> replies = [];
        
        if (data['ok'] && data['result'] != null) {
          for (var update in data['result']) {
            final message = update['message'];
            if (message != null && message['text'] != null) {
              final text = message['text'] as String;
              print('Проверяем сообщение: $text');
              
              if (text.startsWith('/reply ')) {
                print('Найден ответ: $text');
                final parts = text.split(' ');
                if (parts.length >= 3) {
                  final messageId = parts[1];
                  final reply = parts.sublist(2).join(' ');
                  
                  replies.add({
                    'messageId': messageId,
                    'reply': reply,
                    'timestamp': message['date'],
                  });
                  
                  print('Добавлен ответ для ID $messageId: $reply');
                }
              }
            }
          }
        }
        
        print('Всего найдено ответов: ${replies.length}');
        return replies;
      }
    } catch (e) {
      print('Ошибка проверки ответов: $e');
    }
    
    return [];
  }
} 