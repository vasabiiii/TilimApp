import 'package:flutter/material.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/achievements/screens/achievements_screen.dart';
import '../../../features/lessons/screens/lesson_screen.dart';
import '../../../features/ai_assistant/screens/ai_chat_screen.dart';
import '../../../core/widgets/app_header.dart';
import '../models/section_model.dart';
import '../services/sections_provider.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/services/wrong_answers_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/profile/services/profile_service.dart';

class MainScreen extends StatefulWidget {
  final AuthService authService;

  const MainScreen({
    required this.authService,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final SectionsProvider _sectionsProvider = SectionsProvider();
  List<SectionModel> _sections = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _currentSection = '';
  Color _currentSectionColor = const Color(0xFF6B73FF);
  bool _isSubscribed = false;

  final List<Widget> _screens = [
    const SizedBox(),
    const SizedBox(),
    const SizedBox(),
    const AchievementsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSections();
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void updateCurrentSection(String section, Color color) {
    setState(() {
      _currentSection = section;
      _currentSectionColor = color;
    });
  }

  Future<void> _loadSections() async {
    try {
      await _sectionsProvider.loadSections(1);
      setState(() {
        _sections = _sectionsProvider.sections;
        _isLoading = false;
        _screens[0] = _HomeView(
          sections: _sections,
          onSectionChange: updateCurrentSection,
          authService: widget.authService,
        );
        if (_sections.isNotEmpty) {
          _currentSection = _sections[0].title;
          _currentSectionColor = _sections[0].color;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки разделов: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final profileService = ProfileService();
    final accessToken = await widget.authService.getAccessToken() ?? '';
    final result = await profileService.getProfile(accessToken);
    if (result['success'] == true) {
      setState(() {
        _isSubscribed = result['data']['is_subscribed'] ?? false;
      });
    }
  }

  void _navigateToHome() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: _selectedIndex,
      onTap: _onItemTapped,
      body: RepaintBoundary(
        child: Column(
          children: [
            SafeArea(
              child: RepaintBoundary(
                child: AppHeader(
                  onLogoTap: _navigateToHome,
                  onAITap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final wrongAnswersService = WrongAnswersService(prefs, widget.authService);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AIChatScreen(
                          wrongAnswersService: wrongAnswersService,
                        ),
                      ),
                    );
                  },
                  isSubscribed: _isSubscribed,
                ),
              ),
            ),
            if (_selectedIndex == 0 && !_isLoading && _error == null)
              RepaintBoundary(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _currentSectionColor,
                        _currentSectionColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _currentSectionColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Текущий раздел',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentSection,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : RepaintBoundary(
                          key: ValueKey(_selectedIndex),
                          child: _screens[_selectedIndex],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  final List<SectionModel> sections;
  final Function(String, Color) onSectionChange;
  final AuthService authService;

  const _HomeView({
    required this.sections,
    required this.onSectionChange,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final ScrollController _scrollController = ScrollController();
  String _currentSection = '';
  DateTime _lastScrollUpdate = DateTime.now();
  static const Duration _scrollThrottleDuration = Duration(milliseconds: 16); 
  

  static const double _sectionItemHeight = 90.0;
  static const double _sectionPadding = 24.0;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.sections.isNotEmpty ? widget.sections.first.title : '';
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.sections.isEmpty) return;
    

    final now = DateTime.now();
    if (now.difference(_lastScrollUpdate) < _scrollThrottleDuration) return;
    _lastScrollUpdate = now;
    
    final offset = _scrollController.offset;
    double accumulatedHeight = 0;
    
    for (var section in widget.sections) {
      final sectionHeight = (section.levels.length * _sectionItemHeight) + _sectionPadding;
      
      if (offset < accumulatedHeight + sectionHeight) {
        if (_currentSection != section.title) {
          widget.onSectionChange(section.title, section.color);
          setState(() {
            _currentSection = section.title;
          });
        }
        break;
      }
      accumulatedHeight += sectionHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.sections.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 500,
      itemBuilder: (context, index) => _buildModernSection(widget.sections[index]),
    );
  }

  Widget _buildModernSection(SectionModel section) {
    final isFirstSection = widget.sections.first.id == section.id;
    
    return RepaintBoundary(
      child: Column(
        children: [
          if (!isFirstSection) _buildSectionDivider(section),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ModernLevelsList(
              section: section,
              itemCount: section.levels.length,
              authService: widget.authService,
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(SectionModel section) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: section.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                section.title.toUpperCase(),
                style: TextStyle(
                  color: section.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernLevelsList extends StatelessWidget {
  final SectionModel section;
  final int itemCount;
  final AuthService authService;

  const _ModernLevelsList({
    required this.section,
    required this.itemCount,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width - 40;
    const double levelSize = 70.0;
    const double maxOffset = 100.0;
    final double containerHeight = itemCount * 90.0;


    final levelWidgets = <Widget>[];
    
    for (int index = 0; index < itemCount && index < section.levels.length; index++) {
      final level = section.levels[index];
      final groupIndex = index ~/ 4;
      final isMovingRight = groupIndex.isEven;
      final positionInGroup = index % 4;
      
      final progress = isMovingRight 
          ? positionInGroup / 3.0 
          : 1.0 - (positionInGroup / 3.0);
      
      final offset = maxOffset * progress - maxOffset / 2;
      final yPosition = index * 90.0;

      levelWidgets.add(
        Positioned(
          left: screenWidth / 2 + offset - levelSize / 2,
          top: yPosition,
          child: RepaintBoundary(
            key: ValueKey('level_${section.id}_${level.id}'),
            child: _DuolingoLevelButton(
              level: level,
              color: section.color,
              size: levelSize,
              authService: authService,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: containerHeight,
      child: Stack(
        children: levelWidgets,
      ),
    );
  }
}

class _DuolingoLevelButton extends StatefulWidget {
  final LevelModel level;
  final Color color;
  final double size;
  final AuthService authService;

  const _DuolingoLevelButton({
    required this.level,
    required this.color,
    required this.size,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<_DuolingoLevelButton> createState() => _DuolingoLevelButtonState();
}

class _DuolingoLevelButtonState extends State<_DuolingoLevelButton> {
  double _scale = 1.0;
  bool _isAnimating = false;
  

  late final BoxDecoration _containerDecoration;
  late final Widget _contentWidget;

  @override
  void initState() {
    super.initState();
    _initializeDecorations();
  }

  void _initializeDecorations() {
    _containerDecoration = BoxDecoration(
      color: widget.level.isLocked ? Colors.grey[300] : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(
        color: widget.level.isLocked 
            ? Colors.grey[400]! 
            : widget.color,
        width: 4,
      ),
      boxShadow: [
        BoxShadow(
          color: widget.level.isLocked 
              ? Colors.grey.withOpacity(0.2)
              : widget.color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );

    _contentWidget = _buildContent();
  }

  Widget _buildContent() {
    if (widget.level.isLocked) {
      return Icon(
        Icons.lock_rounded,
        color: Colors.grey[600],
        size: widget.size * 0.4,
      );
    } else if (widget.level.isCompleted) {
      return Icon(
        Icons.star_rounded,
        color: const Color(0xFFFFD700),
        size: widget.size * 0.6,
      );
    } else {
      return Text(
        widget.level.number.toString(),
        style: TextStyle(
          color: widget.color,
          fontSize: widget.size * 0.35,
          fontWeight: FontWeight.w800,
        ),
      );
    }
  }

  void _showLessonModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LessonModal(
        level: widget.level,
        color: widget.color,
        authService: widget.authService,
      ),
    );
    if (result == true && context.mounted) {
      final mainState = context.findAncestorStateOfType<_MainScreenState>();
      if (mainState != null) {
        await mainState._loadSections();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ValueKey('level_${widget.level.id}_${widget.level.isCompleted}_${widget.level.isLocked}'),
      child: GestureDetector(
        onTap: widget.level.isLocked ? null : () async {
          if (_isAnimating) return;
          setState(() {
            _scale = 0.96;
            _isAnimating = true;
          });
          await Future.delayed(const Duration(milliseconds: 80));
          setState(() {
            _scale = 1.0;
            _isAnimating = false;
          });
          _showLessonModal(context);
        },
        child: AnimatedScale(
          scale: widget.level.isLocked ? 1.0 : _scale,
          duration: const Duration(milliseconds: 80),
          child: Opacity(
            opacity: widget.level.isLocked ? 0.6 : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: _containerDecoration,
              child: Center(
                child: _contentWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonModal extends StatelessWidget {
  final LevelModel level;
  final Color color;
  final AuthService authService;

  const _LessonModal({
    required this.level,
    required this.color,
    required this.authService,
    Key? key,
  }) : super(key: key);

  void _startLesson(BuildContext context) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          lessonId: level.id,
          lessonTitle: 'Урок ${level.number}',
          lessonColor: color,
          authService: authService,
        ),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  RepaintBoundary(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            center: const Alignment(-0.3, -0.3),
                            radius: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level.number.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Урок ${level.number}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+50 XP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: _AnimatedButton(
                      onPressed: () => _startLesson(context),
                      color: color,
                      child: const Text(
                        'НАЧАТЬ УРОК',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.color,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  double _scale = 1.0;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(widget.color),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(56)),
      shape: MaterialStateProperty.all(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => states.contains(MaterialState.pressed)
            ? widget.color.withOpacity(0.7)
            : null,
      ),
      animationDuration: const Duration(milliseconds: 80),
    );

    return GestureDetector(
      onTap: () async {
        if (_isAnimating) return;
        setState(() {
          _scale = 0.96;
          _isAnimating = true;
        });
        await Future.delayed(const Duration(milliseconds: 80));
        setState(() {
          _scale = 1.0;
          _isAnimating = false;
        });
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: ElevatedButton(
          onPressed: null,
          style: style,
          child: widget.child,
        ),
      ),
    );
  }
} 