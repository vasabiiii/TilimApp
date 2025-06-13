import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Достижения',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            _buildProgressSection(context),
            const SizedBox(height: 32),
            _buildAchievementsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общий прогресс',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '0/20',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0,
            backgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    final achievements = [
      _Achievement(
        'Первые шаги',
        'Завершите первый урок',
        Icons.stars,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Огненная серия',
        '3 дня подряд занятий',
        Icons.local_fire_department,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Словарный запас',
        'Выучите 50 слов',
        Icons.psychology,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/50',
      ),
      _Achievement(
        'Мастер произношения',
        'Идеальное произношение',
        Icons.record_voice_over,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/10',
      ),
      _Achievement(
        'Грамматика',
        'Изучите основы грамматики',
        Icons.menu_book,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/5',
      ),
      _Achievement(
        'Разговорный',
        'Пройдите диалоги',
        Icons.chat_bubble,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/10',
      ),
      _Achievement(
        'Эксперт',
        'Достигните 5 уровня',
        Icons.emoji_events,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/5',
      ),
      _Achievement(
        'Путешественник',
        'Изучите темы о путешествиях',
        Icons.flight,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Гурман',
        'Изучите тему еды',
        Icons.restaurant,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Спортсмен',
        'Изучите тему спорта',
        Icons.sports_soccer,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Семьянин',
        'Изучите тему семьи',
        Icons.family_restroom,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Зоолог',
        'Изучите тему животных',
        Icons.pets,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Быстрый старт',
        '5 уроков за день',
        Icons.speed,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Ночной учитель',
        'Занимайтесь ночью',
        Icons.nightlight,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Ранняя пташка',
        'Занимайтесь утром',
        Icons.wb_sunny,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Перфекционист',
        '100% в тесте',
        Icons.done_all,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Марафонец',
        '30 дней подряд',
        Icons.calendar_month,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/30',
      ),
      _Achievement(
        'Помощник',
        'Помогите другу',
        Icons.people,
        Theme.of(context).colorScheme.secondary,
        false,
      ),
      _Achievement(
        'Коллекционер',
        'Соберите все достижения',
        Icons.collections,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/20',
      ),
      _Achievement(
        'Профессионал',
        'Достигните 10 уровня',
        Icons.workspace_premium,
        Theme.of(context).colorScheme.secondary,
        false,
        '0/10',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(context, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, _Achievement achievement) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(
            achievement.unlocked ? 1.0 : 0.3
          ),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: achievement.unlocked 
                ? theme.colorScheme.secondary
                : theme.colorScheme.secondary.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (achievement.progress != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                achievement.progress!,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final String? progress;

  _Achievement(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.unlocked, [
    this.progress,
  ]);
} 