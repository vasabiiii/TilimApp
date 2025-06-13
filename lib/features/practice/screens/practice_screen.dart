import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_header.dart';
import '../../../features/lessons/screens/lesson_screen.dart';
import '../../../features/auth/services/auth_service.dart';

class PracticeScreen extends StatefulWidget {
  final AuthService authService;

  const PracticeScreen({
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    final routes = {
      0: '/main',
      1: '/leaderboard',
      2: '/practice',
      3: '/profile',
    };
    
    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: _selectedIndex,
      onTap: _onItemTapped,
      body: Column(
        children: [
          SafeArea(
            child: AppHeader(
              onLogoTap: _navigateToHome,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Топ задания',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: Color(0xFF2B217F),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Color(0xFFFFC700), size: 30),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildTaskCard(
                      color: const Color(0xFF22C55E),
                      icon: Icons.description_rounded,
                      title: 'Понимание текста',
                      badge: 'НОВОЕ',
                      badgeColor: const Color(0xFF22C55E),
                      description: 'Прочитайте интересный текст на казахском языке и ответьте на вопрос по содержанию',
                      buttonText: 'Начать задание',
                      buttonColor: const Color(0xFF22C55E),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonScreen(
                              lessonId: 100,
                              lessonTitle: 'Понимание текста',
                              lessonColor: const Color(0xFF22C55E),
                              authService: widget.authService,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildTaskCard(
                      color: const Color(0xFF2563EB),
                      icon: Icons.link_rounded,
                      title: 'Найти пары слов',
                      badge: 'ПОПУЛЯРНОЕ',
                      badgeColor: const Color(0xFF2563EB),
                      description: 'Соедините казахские слова с их русскими переводами и улучшите словарный запас',
                      buttonText: 'Начать задание',
                      buttonColor: const Color(0xFF2563EB),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonScreen(
                              lessonId: 101,
                              lessonTitle: 'Найти пары слов',
                              lessonColor: const Color(0xFF2563EB),
                              authService: widget.authService,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildTaskCard(
                      color: const Color(0xFFF59E42),
                      icon: Icons.volume_up_rounded,
                      title: 'Аудио урок',
                      badge: 'ЭКСКЛЮЗИВ',
                      badgeColor: const Color(0xFFF59E42),
                      description: 'Прослушайте аудио на казахском языке и составьте предложение в правильном порядке',
                      buttonText: 'Начать задание',
                      buttonColor: const Color(0xFFF59E42),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonScreen(
                              lessonId: 102,
                              lessonTitle: 'Аудио урок',
                              lessonColor: const Color(0xFFF59E42),
                              authService: widget.authService,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required Color color,
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 