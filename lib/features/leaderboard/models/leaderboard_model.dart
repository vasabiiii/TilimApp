import 'package:flutter/material.dart';

enum League {
  gold,
  silver,
  bronze,
  none;

  String get displayName {
    switch (this) {
      case League.gold:
        return 'Золотая лига';
      case League.silver:
        return 'Серебряная лига';
      case League.bronze:
        return 'Бронзовая лига';
      case League.none:
        return 'Без лиги';
    }
  }

  Color get color {
    switch (this) {
      case League.gold:
        return const Color(0xFFFFC800);
      case League.silver:
        return const Color(0xFFC0C0C0);
      case League.bronze:
        return const Color(0xFFCD7F32);
      case League.none:
        return const Color(0xFF6B73FF);
    }
  }

  IconData get icon {
    switch (this) {
      case League.gold:
        return Icons.emoji_events;
      case League.silver:
        return Icons.military_tech;
      case League.bronze:
        return Icons.workspace_premium;
      case League.none:
        return Icons.person;
    }
  }

  static League getLeagueByXP(int xpPoints) {
    if (xpPoints >= 5000) return League.gold;
    if (xpPoints >= 400) return League.silver;
    if (xpPoints >= 100) return League.bronze;
    return League.none;
  }
}

class LeaderboardEntry {
  final int userId;
  final String username;
  final int xpPoints;
  final String image;
  final League league;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.xpPoints,
    required this.image,
    League? league,
  }) : league = league ?? League.getLeagueByXP(xpPoints);

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      xpPoints: json['xp_points'] as int,
      image: json['image'] as String,
    );
  }
} 