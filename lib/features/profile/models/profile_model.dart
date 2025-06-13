class ProfileModel {
  final int userId;
  final String username;
  final DateTime registrationDate;
  final String? image;
  final int streakDays;
  final int xpPoints;
  final int wordsLearned;
  final int lessonsDone;
  final bool isSubscribed;

  const ProfileModel({
    required this.userId,
    required this.username,
    required this.registrationDate,
    this.image,
    required this.streakDays,
    required this.xpPoints,
    required this.wordsLearned,
    required this.lessonsDone,
    required this.isSubscribed,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      image: json['image'] as String?,
      streakDays: json['streak_days'] as int,
      xpPoints: json['xp_points'] as int,
      wordsLearned: json['words_learned'] as int,
      lessonsDone: json['lessons_done'] as int,
      isSubscribed: json['is_subscribed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'registration_date': registrationDate.toIso8601String(),
      'image': image,
      'streak_days': streakDays,
      'xp_points': xpPoints,
      'words_learned': wordsLearned,
      'lessons_done': lessonsDone,
      'is_subscribed': isSubscribed,
    };
  }
} 