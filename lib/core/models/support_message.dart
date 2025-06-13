class SupportMessage {
  final String id;
  final String message;
  final String email;
  final DateTime timestamp;
  final String? reply;
  final DateTime? replyTimestamp;
  final String status; 

  SupportMessage({
    required this.id,
    required this.message,
    required this.email,
    required this.timestamp,
    this.reply,
    this.replyTimestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'email': email,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reply': reply,
      'replyTimestamp': replyTimestamp?.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      message: json['message'],
      email: json['email'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      reply: json['reply'],
      replyTimestamp: json['replyTimestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['replyTimestamp'])
          : null,
      status: json['status'] ?? 'pending',
    );
  }

  SupportMessage copyWith({
    String? reply,
    DateTime? replyTimestamp,
    String? status,
  }) {
    return SupportMessage(
      id: id,
      message: message,
      email: email,
      timestamp: timestamp,
      reply: reply ?? this.reply,
      replyTimestamp: replyTimestamp ?? this.replyTimestamp,
      status: status ?? this.status,
    );
  }
} 