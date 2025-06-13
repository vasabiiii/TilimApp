import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/practice/screens/practice_screen.dart';

class AppRouter {
  static final AuthService _authService = AuthService();

  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const SplashScreen(),
    '/login': (context) => LoginScreen(authService: _authService),
    '/register': (context) => RegisterScreen(authService: _authService),
    '/main': (context) => MainScreen(authService: _authService),
    '/profile': (context) => ProfileScreen(authService: _authService),
    '/leaderboard': (context) => const LeaderboardScreen(),
    '/practice': (context) => PracticeScreen(
      authService: AuthService(),
    ),
  };
} 