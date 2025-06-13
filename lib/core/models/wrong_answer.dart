class WrongAnswer {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final int lessonId;

  WrongAnswer({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.lessonId,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'userAnswer': userAnswer,
    'correctAnswer': correctAnswer,
    'lessonId': lessonId,
  };

  factory WrongAnswer.fromJson(Map<String, dynamic> json) => WrongAnswer(
    question: json['question'],
    userAnswer: json['userAnswer'],
    correctAnswer: json['correctAnswer'],
    lessonId: json['lessonId'],
  );
} 