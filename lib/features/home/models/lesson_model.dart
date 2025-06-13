class LessonModel {
  final int id;
  final String title;
  final int xp;
  final String status;

  const LessonModel({
    required this.id,
    required this.title,
    required this.xp,
    required this.status,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as int,
      title: json['title'] as String,
      xp: json['xp'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'xp': xp,
      'status': status,
    };
  }
} 