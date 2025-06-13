import 'package:flutter/material.dart';
import 'lesson_model.dart';

class LevelModel {
  final int id;
  final int number;
  final bool isCompleted;
  final bool isLocked;

  const LevelModel({
    required this.id,
    required this.number,
    required this.isCompleted,
    this.isLocked = true,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as int,
      number: json['number'] as int,
      isCompleted: json['isCompleted'] as bool,
      isLocked: json['isLocked'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
    };
  }
}

class SectionModel {
  final int id;
  final String title;
  final List<LessonModel> lessons;
  final String? moduleTitle;
  final int? moduleId;
  
  String get moduleText => moduleTitle != null ? moduleTitle! : 'МОДУЛЬ';
  Color get color => _getColorForSection(id);
  List<LevelModel> get levels => _convertLessonsToLevels(lessons);

  const SectionModel({
    required this.id,
    required this.title,
    required this.lessons,
    this.moduleTitle,
    this.moduleId,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as int,
      title: json['title'] as String,
      lessons: (json['lessons'] as List)
          .map((lesson) => LessonModel.fromJson(lesson))
          .toList(),
      moduleTitle: json['moduleTitle'] as String?,
      moduleId: json['moduleId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'moduleTitle': moduleTitle,
      'moduleId': moduleId,
    };
  }

  Color _getColorForSection(int id) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.yellow,
      Colors.green,
    ];
    return colors[id % colors.length];
  }

  List<LevelModel> _convertLessonsToLevels(List<LessonModel> lessons) {
    return List.generate(
      lessons.length,
      (index) => LevelModel(
        id: lessons[index].id,
        number: index + 1,
        isCompleted: lessons[index].status == 'Completed',
        isLocked: lessons[index].status == 'Locked',
      ),
    );
  }
} 