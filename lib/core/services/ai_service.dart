import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String? _apiKey;

  void initialize() {
    try {
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('OPENAI_API_KEY не найден в .env файле');
      }
      print('API ключ успешно загружен: ${_apiKey!.substring(0, 5)}...');
      OpenAI.apiKey = _apiKey!;
    } catch (e) {
      print('Ошибка при инициализации AIService: $e');
      rethrow;
    }
  }

  Future<String> getExplanation(String question, String wrongAnswer) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        return 'Ошибка: API ключ не установлен';
      }

      final completion = await OpenAI.instance.chat.create(
        model: 'gpt-4',
        maxTokens: 350,
        temperature: 0.7,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'Ты помощник по изучению казахского языка. Твоя задача - помогать ученикам разбирать их ошибки. Давай подробные и понятные объяснения. Ты знаешь казахский язык и можешь определять значения казахских слов.'
              ),
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'Объясняй ошибки подробно на русском языке. Когда упоминаешь казахские слова, заключай их в кавычки. Всегда указывай перевод и значение слов. Помни, что ответы пользователя могут быть на казахском языке, и их нужно проверять как казахские слова.'
              ),
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'В своем ответе обязательно укажи:\n' +
                '1. Правильный ответ с переводом (Например: Правильный ответ: "ана" - мама)\n' +
                '2. Объясни, почему ответ неверный (Ваш ответ "тут его неверный ответ", так как "его неверный ответ" означает "тут даешь определение слову"; правильный ответ будет " тут правильный ответ", так как "и тут ты даешь определение правильному ответу")\n' +
                '3. Дай 1-2 примера использования правильного слова в предложениях с переводом'
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'Вопрос: $question\nОтвет пользователя: $wrongAnswer\nПомоги разобрать ошибку. Помни, что ответ пользователя может быть на казахском языке:'
              ),
            ],
          ),
        ],
      );

      final content = completion.choices.first.message.content;
      if (content != null && content.isNotEmpty) {
        final text = content.first.text;
        if (text != null) {
          return text;
        }
      }
      return 'Нет ответа';
    } catch (e) {
      print('Ошибка при получении ответа: $e');
      return 'Ошибка при получении ответа';
    }
  }
} 