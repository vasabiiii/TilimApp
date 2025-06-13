import 'dart:convert';

class ExerciseModel {
  final int id;
  final String text;
  final String image;
  final String questionText;
  final List<AnswerModel> answers;
  final String typeCode;
  final Map<String, dynamic>? audio;

  const ExerciseModel({
    required this.id,
    required this.text,
    required this.image,
    required this.questionText,
    required this.answers,
    required this.typeCode,
    this.audio,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['image'] as String? ?? '';
    print('Парсим упражнение: id=${json['id']}, image="$imageUrl"');
    
    return ExerciseModel(
      id: json['id'] as int,
      text: _decodeText(json['text'] as String? ?? ''),
      image: imageUrl,
      questionText: _decodeText(json['question_text'] as String? ?? ''),
      answers: (json['answers'] as List?)
          ?.map((answer) => AnswerModel.fromJson(answer as Map<String, dynamic>))
          .toList() ?? [],
      typeCode: json['type_code'] as String? ?? 'test',
      audio: json['audio'] as Map<String, dynamic>?,
    );
  }
}

class AnswerModel {
  final int id;
  final String text;
  final String? image;
  final bool isCorrect;

  const AnswerModel({
    required this.id,
    required this.text,
    this.image,
    required this.isCorrect,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    bool convertToBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    }

    return AnswerModel(
      id: json['id'] as int,
      text: _decodeText(json['text'] as String? ?? ''),
      image: json['image'] as String?,
      isCorrect: convertToBool(json['is_correct']),
    );
  }
}

class LessonModel {
  final int id;
  final String title;
  final int xp;
  final List<ExerciseModel> exercises;

  const LessonModel({
    required this.id,
    required this.title,
    required this.xp,
    required this.exercises,
  });

  factory LessonModel.fromJson(dynamic json) {
    if (json is List) {
      List<ExerciseModel> exercises = 
          json.map((item) => ExerciseModel.fromJson(item as Map<String, dynamic>)).toList();
      
      return LessonModel(
        id: 0,
        title: '',
        xp: 0,
        exercises: exercises,
      );
    } 
    else if (json is Map<String, dynamic> && json.containsKey('exercises')) {
      return LessonModel(
        id: json['id'] as int? ?? 0, 
        title: _decodeText(json['title'] as String? ?? ''),
        xp: json['xp'] as int? ?? 0,
        exercises: (json['exercises'] as List?)
            ?.map((exercise) => ExerciseModel.fromJson(exercise as Map<String, dynamic>))
            .toList() ?? [],
      );
    } 
    else {
      print('Неизвестный формат JSON: $json');
      return LessonModel(
        id: 0,
        title: '',
        xp: 0,
        exercises: [],
      );
    }
  }
}

String _decodeText(String text) {
  try {
    if (text.contains('Ð') || text.contains('Ò')) {
      List<int> bytes = [];
      for (int i = 0; i < text.length; i++) {
        bytes.add(text.codeUnitAt(i));
      }
      return utf8.decode(bytes, allowMalformed: true);
    }
    return text;
  } catch (e) {
    print('Ошибка декодирования текста: $e');
    return text;
  }
} 