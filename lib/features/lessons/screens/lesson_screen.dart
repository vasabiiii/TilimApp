import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../models/quiz_question_model.dart';
import '../services/lesson_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/wrong_answers_service.dart';
import '../../../core/models/wrong_answer.dart';
import '../../../features/auth/services/auth_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; 

class LessonScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final Color lessonColor;
  final AuthService authService;

  const LessonScreen({
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonColor,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  final LessonService _lessonService = LessonService();
  List<ExerciseModel> _exercises = [];
  int _currentExerciseIndex = 0;
  int? _selectedAnswerId;
  bool _isLoading = true;
  bool _isCompletingLesson = false;
  String? _errorMessage;
  bool _isAnswerSubmitted = false;
  int _correctAnswers = 0;
  bool _exercisesCompleted = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  bool _isPlayerInitialized = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipping = false;
  int? _nextIndex;
  bool _starsDone = false;
  double _overlayOpacity = 0.7;
  bool _showStaticStars = false;
  List<bool> _starActive = [false, false, false];

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _initSoundPlayer();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipController.value = 1.0;
    _flipController.addListener(_handleFlipChange);
  }

  void _handleFlipChange() {
    if (_isFlipping && _flipAnimation.value >= 0.5 && _nextIndex != null) {
      setState(() {
        _currentExerciseIndex = _nextIndex!;
        _selectedAnswerId = null;
        _isAnswerSubmitted = false;
        _nextIndex = null;
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _soundPlayer.closePlayer();
    _flipController.removeListener(_handleFlipChange);
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await _lessonService.getLesson(widget.lessonId);
      
      if (lesson != null && lesson.exercises.isNotEmpty) {
        setState(() {
          _exercises = lesson.exercises;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить урок';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки урока: $e';
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int answerId) {
    if (!_isAnswerSubmitted) {
      setState(() {
        _selectedAnswerId = answerId;
      });
    }
  }

  Future<void> _showDuolingoBottomSheet({required bool isCorrect, required String message}) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AnimatedDuolingoSheet(
          isCorrect: isCorrect,
          message: message,
          onContinue: () {
            Navigator.of(context).pop();
            _nextExercise();
          },
        );
      },
    );
  }

  void _submitAnswer() async {
    if (_selectedAnswerId == null) {
      return;
    }
    
    final currentExercise = _exercises[_currentExerciseIndex];
    final selectedAnswer = currentExercise.answers.firstWhere(
      (answer) => answer.id == _selectedAnswerId,
      orElse: () => AnswerModel(id: -1, text: '', isCorrect: false),
    );
    final correctAnswer = currentExercise.answers.firstWhere(
      (answer) => answer.isCorrect,
      orElse: () => AnswerModel(id: -1, text: '', isCorrect: true),
    );
    
    if (selectedAnswer.isCorrect) {
      _updateProgress();
      _playSuccessSound();
      
      final List<String> successMessages = [
        'Превосходно!',
        'Круто!',
        'Отлично!',
        'Молодец!',
        'Супер!',
        'Правильно!',
        'Замечательно!',
      ];
      final randomMessage = successMessages[DateTime.now().millisecondsSinceEpoch % successMessages.length];
      _showDuolingoBottomSheet(isCorrect: true, message: randomMessage);
    } else {
      _playWrongSound();
      
      final prefs = await SharedPreferences.getInstance();
      final wrongAnswersService = WrongAnswersService(prefs, widget.authService);
      await wrongAnswersService.saveWrongAnswer(WrongAnswer(
        question: currentExercise.questionText,
        userAnswer: selectedAnswer.text,
        correctAnswer: correctAnswer.text,
        lessonId: widget.lessonId,
      ));
      
      _showDuolingoBottomSheet(
        isCorrect: false,
        message: 'Неправильный ответ: правильный — ${correctAnswer.text}',
      );
    }
    
    setState(() {
      _isAnswerSubmitted = true;
    });
  }

  void _updateProgress() {
    final previousProgress = _correctAnswers / _exercises.length;
    setState(() {
      _correctAnswers++;
    });
    final newProgress = _correctAnswers / _exercises.length;
    
    _progressAnimation = Tween<double>(
      begin: previousProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward(from: 0.0);
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1 && !_isFlipping) {
      _isFlipping = true;
      _nextIndex = _currentExerciseIndex + 1;
      _flipController.forward(from: 0.0).then((_) {
        _isFlipping = false;
      });
    } else if (!_isFlipping) {
      setState(() {
        _exercisesCompleted = true;
      });
    }
  }

  void _restartExercises() {
    setState(() {
      _currentExerciseIndex = 0;
      _selectedAnswerId = null;
      _isAnswerSubmitted = false;
      _correctAnswers = 0;
      _exercisesCompleted = false;
      _starsDone = false;
      _showStaticStars = false;
      _starActive = [false, false, false];
      _overlayOpacity = 0.7;
    });
  }

  Future<void> _initSoundPlayer() async {
    try {
      await _soundPlayer.openPlayer();
      setState(() {
        _isPlayerInitialized = true;
      });
    } catch (e) {
    }
  }

  Future<void> _playSuccessSound() async {
    if (_isPlayerInitialized) {
      try {
        await _soundPlayer.stopPlayer();
        await _soundPlayer.startPlayer(
          fromDataBuffer: await _loadAsset('assets/sounds/success_bell.mp3'),
          codec: Codec.mp3,
          whenFinished: () {},
        );
        await _soundPlayer.setVolume(0.3);
      } catch (e) {
      }
    }
  }

  Future<void> _playFinalSuccessSound() async {
    if (_isPlayerInitialized) {
      try {
        await _soundPlayer.stopPlayer();
        await _soundPlayer.startPlayer(
          fromDataBuffer: await _loadAsset('assets/sounds/success-1.mp3'),
          codec: Codec.mp3,
          whenFinished: () {},
        );
        await _soundPlayer.setVolume(0.2);
      } catch (e) {
      }
    }
  }

  Future<void> _playWrongSound() async {
    if (_isPlayerInitialized) {
      try {
        await _soundPlayer.stopPlayer();
        await _soundPlayer.startPlayer(
          fromDataBuffer: await _loadAsset('assets/sounds/wrong-answer.mp3'),
          codec: Codec.mp3,
          whenFinished: () {},
        );
        await _soundPlayer.setVolume(0.1);
      } catch (e) {
        //
      }
    }
  }

  Future<Uint8List> _loadAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RepaintBoundary(
          child: Stack(
            children: [
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                          onPressed: _showExitConfirmSheet,
                          tooltip: 'Назад',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedProgressBar(
                          progress: _progressAnimation.value,
                          totalSteps: _exercises.length,
                          color: widget.lessonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          )
                        : _exercisesCompleted
                            ? _buildExercisesCompletedView(theme)
                            : _buildExerciseView(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseView(ThemeData theme) {
    final currentExercise = _exercises[_currentExerciseIndex];
    if (currentExercise.typeCode == 'pairs') {
      return _PairsExerciseWidget(
        key: ValueKey(_currentExerciseIndex),
        answers: currentExercise.answers,
        lessonColor: widget.lessonColor,
        authService: widget.authService,
        onSubmit: (isCorrect) {
          if (isCorrect) {
            _updateProgress();
            _playSuccessSound();
            _showDuolingoBottomSheet(isCorrect: true, message: 'Отлично! Все пары верны.');
          } else {
            _playWrongSound();
            _showDuolingoBottomSheet(isCorrect: false, message: 'Есть ошибки в парах.');
          }
          setState(() {
            _isAnswerSubmitted = true;
          });
        },
      );
    }
    if (currentExercise.typeCode == 'shuffle') {
      return _ShuffleExerciseWidget(
        key: ValueKey(_currentExerciseIndex),
        words: currentExercise.text.split('|'),
        correctOrder: currentExercise.answers.isNotEmpty
            ? currentExercise.answers.first.text.split('|')
            : [],
        lessonColor: widget.lessonColor,
        authService: widget.authService,
        audio: currentExercise.audio,
        onSubmit: (isCorrect) {
          if (isCorrect) {
            _updateProgress();
            _playSuccessSound();
            _showDuolingoBottomSheet(isCorrect: true, message: 'Превосходно!');
          } else {
            _playWrongSound();
            _showDuolingoBottomSheet(isCorrect: false, message: 'Порядок слов неверный!');
          }
          setState(() {
            _isAnswerSubmitted = true;
          });
        },
      );
    }
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        double angle = _flipAnimation.value * 3.14159; 
        bool isSecondHalf = _flipAnimation.value >= 0.5;
        Widget content = Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: currentExercise.image.isNotEmpty
                      ? Image.network(
                          currentExercise.image,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const _ImagePlaceholder();
                          },
                        )
                      : const _ImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 24),
              _QuestionBlock(
                questionText: currentExercise.questionText,
                answers: currentExercise.answers,
                isAnswerSubmitted: _isAnswerSubmitted,
                selectedAnswerId: _selectedAnswerId,
                lessonColor: widget.lessonColor,
                onSelect: _selectAnswer,
                buildAnswerTile: (answer) => _buildAnswerTile(answer, theme),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _AnimatedScaleButton(
                  onTap: _isAnswerSubmitted ? _nextExercise : _submitAnswer,
                  backgroundColor: widget.lessonColor,
                  foregroundColor: Colors.white,
                  child: Text(
                    _isAnswerSubmitted ? 'ПРОДОЛЖИТЬ' : 'ПРОВЕРИТЬ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isSecondHalf
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                  child: content,
                )
              : content,
        );
      },
    );
  }

  Widget _buildAnswerTile(AnswerModel answer, ThemeData theme) {
    Color? borderColor;
    Color? backgroundColor;
    
    if (_isAnswerSubmitted) {
      if (answer.isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
      } else if (answer.id == _selectedAnswerId) {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
      } else {
        borderColor = Colors.grey[300];
        backgroundColor = Colors.grey[50];
      }
    } else if (answer.id == _selectedAnswerId) {
      borderColor = widget.lessonColor;
      backgroundColor = widget.lessonColor.withOpacity(0.1);
    } else {
      borderColor = Colors.grey[300];
      backgroundColor = Colors.white;
    }
    
    return GestureDetector(
      onTap: () => _selectAnswer(answer.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _selectedAnswerId == answer.id 
                    ? (borderColor ?? widget.lessonColor)
                    : Colors.white,
                border: Border.all(
                  color: borderColor ?? Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: _selectedAnswerId == answer.id
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                answer.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: (_isAnswerSubmitted && answer.isCorrect) ||
                          (_selectedAnswerId == answer.id)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesCompletedView(ThemeData theme) {
    final percentage = (_correctAnswers / _exercises.length) * 100;
    final displayPercentage = percentage.round();
    int starCount = percentage >= 100 ? 3 : percentage >= 75 ? 2 : percentage >= 50 ? 1 : 0;
    
    String getMessage() {
      if (percentage >= 100) return 'Превосходно!!!';
      if (percentage >= 75) return 'Замечательно! Но ты можешь лучше!';
      if (percentage >= 50) return 'Неплохо! Но надо больше тренироваться!';
      return 'Надо больше учиться!';
    }

    List<Offset> _starTargetOffsets(Size size) {
      final barY = 120.0;
      final barWidth = size.width - 80;
      final left = Offset(40 + barWidth * 0.2, barY);
      final right = Offset(40 + barWidth * 0.8, barY);
      final center = Offset(40 + barWidth * 0.5, barY - 20);
      
      return [left, right, center];
    }
    
    bool showStars = percentage >= 50;
    void _onStarsEnd() async {
      if (percentage >= 50) {
        _playFinalSuccessSound();
      }
      setState(() {
        _overlayOpacity = 0.0;
        _showStaticStars = true;
        _starActive = [false, false, false];
      });
      
      if (starCount >= 1) {
        setState(() { 
          _starActive[0] = true; 
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (starCount >= 2) {
        setState(() { 
          _starActive[1] = true; 
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (starCount == 3) {
        setState(() { 
          _starActive[2] = true; 
        });
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      setState(() {
        _starsDone = true;
      });
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final staticStarOffsets = _starTargetOffsets(size);
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getMessage(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Вы ответили правильно на $displayPercentage% вопросов',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _AnimatedScaleButton(
                              onTap: _restartExercises,
                              backgroundColor: Colors.white,
                              foregroundColor: widget.lessonColor,
                              borderSide: BorderSide(color: widget.lessonColor, width: 2),
                              minHeight: 56,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Пройти снова',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.lessonColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _AnimatedScaleButton(
                              onTap: _isCompletingLesson ? null : () async {
                                setState(() {
                                  _isCompletingLesson = true;
                                });
                                
                                final success = await _lessonService.completeLesson(widget.lessonId);
                                
                                setState(() {
                                  _isCompletingLesson = false;
                                });
                                
                                if (success) {
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ошибка при завершении урока. Попробуйте еще раз.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              backgroundColor: widget.lessonColor,
                              foregroundColor: Colors.white,
                              child: _isCompletingLesson
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Завершить',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showStars && !_starsDone)
              AnimatedOpacity(
                opacity: _overlayOpacity,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  width: size.width,
                  height: size.height,
                ),
              ),
            if (showStars && !_starsDone)
              SizedBox(
                width: size.width,
                height: size.height,
                child: _AnimatedStarsCelebration(
                  starCount: 3,
                  targetOffsets: _starTargetOffsets(size),
                  onEnd: _onStarsEnd,
                ),
              ),
            if (_showStaticStars && showStars)
              ...List.generate(3, (i) {
                final pos = staticStarOffsets[i];
                final sizeStar = i == 2 ? 77.0 : 48.0;
                final isActive = _starActive[i];
                return AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.star,
                      key: ValueKey(isActive),
                      size: sizeStar,
                      color: isActive ? Colors.amber : Colors.grey[400],
                      shadows: isActive
                          ? [Shadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12)]
                          : [],
                    ),
                  ),
                ).positioned(
                  left: pos.dx - sizeStar / 2,
                  top: pos.dy - sizeStar / 2,
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _showExitConfirmSheet() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 48),
                const SizedBox(height: 16),
                Text(
                  'Ты точно хочешь все бросить и закончить?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Там же немного осталось',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _AnimatedScaleButton(
                        onTap: () => Navigator.of(context).pop(),
                        backgroundColor: widget.lessonColor,
                        foregroundColor: Colors.white,
                        minHeight: 48,
                        child: const Text(
                          'Продолжить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedScaleButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                        minHeight: 48,
                        child: const Text(
                          'Выйти',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final double progress; 
  final int totalSteps;
  final Color color;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.totalSteps,
    required this.color,
  });

  Color _getProgressColor(double value) {
    if (value < 0.5) {

      return Color.lerp(Colors.red, Colors.yellow, value * 2)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.green, (value - 0.5) * 2)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: barWidth * progress,
              height: 24,
              decoration: BoxDecoration(
                color: _getProgressColor(progress),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getProgressColor(progress).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedStarsCelebration extends StatefulWidget {
  final int starCount;
  final VoidCallback onEnd;
  final List<Offset> targetOffsets;

  const _AnimatedStarsCelebration({
    required this.starCount,
    required this.onEnd,
    required this.targetOffsets,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedStarsCelebration> createState() => _AnimatedStarsCelebrationState();
}

class _AnimatedStarsCelebrationState extends State<_AnimatedStarsCelebration> with TickerProviderStateMixin {
  late List<AnimationController> _appearControllers;
  late AnimationController _flyController;
  bool _fly = false;

  @override
  void initState() {
    super.initState();
    _appearControllers = List.generate(3, (i) => AnimationController( 
      vsync: this,
      duration: const Duration(milliseconds: 400),
    ));
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startSequence();
  }

  Future<void> _startSequence() async {

    for (int i = 0; i < 3; i++) { 
      _appearControllers[i].forward();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() { _fly = true; });
    await _flyController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onEnd();
  }

  @override
  void dispose() {
    for (final c in _appearControllers) { c.dispose(); }
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final List<Offset> startOffsets = [
      center + const Offset(-40, 0), 
      center + const Offset(40, 0),  
      center + const Offset(0, -40), 
    ];
    final List<double> starSizes = [48, 48, 64];
    return Stack(
      children: List.generate(3, (i) { 
        return AnimatedBuilder(
          animation: Listenable.merge([_appearControllers[i], _flyController]),
          builder: (context, child) {
            final appear = _appearControllers[i].value;
            final fly = _flyController.value;
            Offset pos = startOffsets[i];
            if (_fly && widget.targetOffsets.length == 3) {
              pos = Offset.lerp(startOffsets[i], widget.targetOffsets[i], fly)!;
            }
            return Positioned(
              left: pos.dx - starSizes[i] / 2,
              top: pos.dy - starSizes[i] / 2,
              child: Opacity(
                opacity: appear,
                child: Transform.scale(
                  scale: appear * (i == 2 ? 1.2 : 1.0),
                  child: Icon(
                    Icons.star,
                    size: starSizes[i],
                    color: Colors.grey[400], 
                    shadows: [
                      Shadow(color: Colors.grey.withOpacity(0.3), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}


extension _WidgetPositioned on Widget {
  Widget positioned({required double left, required double top}) => Positioned(left: left, top: top, child: this);
}

class _AnimatedDuolingoSheet extends StatefulWidget {
  final bool isCorrect;
  final String message;
  final VoidCallback onContinue;
  const _AnimatedDuolingoSheet({
    required this.isCorrect,
    required this.message,
    required this.onContinue,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedDuolingoSheet> createState() => _AnimatedDuolingoSheetState();
}

class _AnimatedDuolingoSheetState extends State<_AnimatedDuolingoSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isCorrect ? Icons.check_circle : Icons.close_rounded,
                    color: widget.isCorrect ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.isCorrect ? Colors.green : Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _AnimatedScaleButton(
                  onTap: widget.onContinue,
                  backgroundColor: widget.isCorrect ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  child: const Text(
                    'ПРОДОЛЖИТЬ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Изображение не загрузилось',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  final String questionText;
  final List<AnswerModel> answers;
  final bool isAnswerSubmitted;
  final int? selectedAnswerId;
  final Color lessonColor;
  final void Function(int) onSelect;
  final Widget Function(AnswerModel) buildAnswerTile;
  const _QuestionBlock({
    required this.questionText,
    required this.answers,
    required this.isAnswerSubmitted,
    required this.selectedAnswerId,
    required this.lessonColor,
    required this.onSelect,
    required this.buildAnswerTile,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 16),
          ...answers.map(buildAnswerTile),
        ],
      ),
    );
  }
}

class _AnimatedScaleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double minHeight;
  final OutlinedBorder shape;
  final BorderSide? borderSide;
  const _AnimatedScaleButton({
    required this.onTap,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    this.minHeight = 56,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    this.borderSide,
    Key? key,
  }) : super(key: key);
  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;
  bool _isAnimating = false;
  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = widget.borderSide == null
        ? ButtonStyle(
            backgroundColor: MaterialStateProperty.all(widget.backgroundColor),
            foregroundColor: MaterialStateProperty.all(widget.foregroundColor),
            minimumSize: MaterialStateProperty.all(Size.fromHeight(widget.minHeight)),
            shape: MaterialStateProperty.all(widget.shape),
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.pressed)
                  ? widget.backgroundColor.withOpacity(0.7)
                  : null,
            ),
            animationDuration: const Duration(milliseconds: 80),
          )
        : OutlinedButton.styleFrom(
            side: widget.borderSide!,
            foregroundColor: widget.foregroundColor,
            minimumSize: Size.fromHeight(widget.minHeight),
            shape: widget.shape,
            backgroundColor: widget.backgroundColor,
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.pressed)
                  ? widget.backgroundColor.withOpacity(0.15)
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
        if (widget.onTap != null) widget.onTap!();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: widget.borderSide == null
            ? ElevatedButton(
                onPressed: null,
                style: style,
                child: widget.child,
              )
            : OutlinedButton(
                onPressed: null,
                style: style,
                child: widget.child,
              ),
      ),
    );
  }
}

class _PairsExerciseWidget extends StatefulWidget {
  final List<AnswerModel> answers;
  final Color lessonColor;
  final AuthService authService;
  final void Function(bool isCorrect) onSubmit;

  const _PairsExerciseWidget({
    required this.answers,
    required this.lessonColor,
    required this.authService,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<_PairsExerciseWidget> createState() => _PairsExerciseWidgetState();
}

class _PairsExerciseWidgetState extends State<_PairsExerciseWidget> {
  late List<String> leftWords;
  late List<String> rightWords;
  late List<String> correctPairs;
  Map<int, int> selectedPairs = {}; 
  int? selectedLeft;
  int? selectedRight;
  bool submitted = false;
  List<bool> rightMatched = [];
  List<bool> leftMatched = [];
  Map<int, bool> pairCorrect = {}; 
  int? lastErrorLeft;
  int? lastErrorRight;

  @override
  void initState() {
    super.initState();
    _initPairs();
  }

  void _initPairs() {
    List<String> left = [];
    List<String> right = [];
    List<String> pairs = [];
    for (final a in widget.answers) {
      final parts = a.text.split('|');
      if (parts.length == 2) {
        left.add(parts[0]);
        right.add(parts[1]);
        pairs.add(a.text);
      }
    }
    left.shuffle(Random());
    right.shuffle(Random());
    leftWords = left;
    rightWords = right;
    correctPairs = pairs;
    rightMatched = List.filled(right.length, false);
    leftMatched = List.filled(left.length, false);
    selectedPairs = {};
    selectedLeft = null;
    selectedRight = null;
    submitted = false;
    pairCorrect = {};
    lastErrorLeft = null;
    lastErrorRight = null;
  }

  void _onLeftTap(int i) {
    if (selectedLeft == i) return;
    setState(() {
      selectedLeft = i;
      lastErrorLeft = null;
      lastErrorRight = null;
    });
  }

  void _onRightTap(int i) async {
    if (rightMatched[i]) return;
    if (selectedLeft == null) return;
    final l = selectedLeft!;
    final pair = '${leftWords[l]}|${rightWords[i]}';
    if (correctPairs.contains(pair)) {
      setState(() {
        selectedPairs[l] = i;
        leftMatched[l] = true;
        rightMatched[i] = true;
        pairCorrect[l] = true;
        selectedLeft = null;
        lastErrorLeft = null;
        lastErrorRight = null;
      });
      if (selectedPairs.length == leftWords.length) {
        Future.delayed(const Duration(milliseconds: 350), () {
          widget.onSubmit(true);
        });
      }
    } else {
      setState(() {
        pairCorrect[l] = false;
        lastErrorLeft = l;
        lastErrorRight = i;
      });
      final prefs = await SharedPreferences.getInstance();
      final wrongAnswersService = WrongAnswersService(prefs, widget.authService);
      await wrongAnswersService.saveWrongAnswer(
        WrongAnswer(
          question: 'Пара: ${leftWords[l]} - ?',
          userAnswer: rightWords[i],
          correctAnswer: correctPairs.firstWhere((p) => p.startsWith('${leftWords[l]}|')).split('|')[1],
          lessonId: 0, 
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Неправильная пара!'),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 800),
        ),
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            pairCorrect.remove(l);
            lastErrorLeft = null;
            lastErrorRight = null;
            selectedLeft = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allMatched = selectedPairs.length == leftWords.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Соедините пары',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Нажмите на слово, затем на его перевод',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(leftWords.length, (i) {
                      final isSelected = selectedLeft == i;
                      final isMatched = leftMatched[i];
                      final isError = lastErrorLeft == i && pairCorrect[i] == false;
                      final isCorrect = pairCorrect[i] == true;
                      return _PairWordTile(
                        text: leftWords[i],
                        isSelected: isSelected,
                        isMatched: isMatched,
                        isError: isError,
                        isCorrect: isCorrect,
                        onTap: () => _onLeftTap(i),
                        showCheck: isMatched,
                        lessonColor: widget.lessonColor,
                        alignLeft: true,
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(rightWords.length, (i) {
                      final isMatched = rightMatched[i];
                      final isError = lastErrorRight == i && lastErrorLeft != null && pairCorrect[lastErrorLeft!] == false;
                      return _PairWordTile(
                        text: rightWords[i],
                        isSelected: false,
                        isMatched: isMatched,
                        isError: isError,
                        isCorrect: isMatched,
                        onTap: () => _onRightTap(i),
                        showCheck: isMatched,
                        lessonColor: widget.lessonColor,
                        alignLeft: false,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PairWordTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isMatched;
  final bool isError;
  final bool isCorrect;
  final VoidCallback onTap;
  final bool showCheck;
  final Color lessonColor;
  final bool alignLeft;

  const _PairWordTile({
    required this.text,
    required this.isSelected,
    required this.isMatched,
    required this.isError,
    required this.isCorrect,
    required this.onTap,
    required this.showCheck,
    required this.lessonColor,
    required this.alignLeft,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    if (isMatched || isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.08);
    } else if (isError) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.08);
    } else if (isSelected) {
      borderColor = lessonColor;
      backgroundColor = lessonColor.withOpacity(0.08);
    } else {
      borderColor = Colors.grey[300]!;
      backgroundColor = Colors.white;
    }
    return GestureDetector(
      onTap: isMatched ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (showCheck && alignLeft)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: (isMatched || isSelected) ? FontWeight.bold : FontWeight.w500,
                  color: Colors.grey[900],
                  fontSize: 18,
                ),
              ),
            ),
            if (showCheck && !alignLeft)
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class ListEquality {
  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _ShuffleExerciseWidget extends StatefulWidget {
  final List<String> words;
  final List<String> correctOrder;
  final Color lessonColor;
  final AuthService authService;
  final dynamic audio;
  final void Function(bool isCorrect) onSubmit;

  const _ShuffleExerciseWidget({
    required this.words,
    required this.correctOrder,
    required this.lessonColor,
    required this.authService,
    this.audio,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<_ShuffleExerciseWidget> createState() => _ShuffleExerciseWidgetState();
}

class _ShuffleExerciseWidgetState extends State<_ShuffleExerciseWidget> {
  late List<String> availableWords;
  List<String> selectedWords = [];
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    availableWords = List.from(widget.words)..shuffle();
    selectedWords = [];
    submitted = false;
  }

  void _onWordTap(String word) {
    setState(() {
      availableWords.remove(word);
      selectedWords.add(word);
    });
  }

  void _onReset() {
    setState(() {
      availableWords = List.from(widget.words)..shuffle();
      selectedWords = [];
      submitted = false;
    });
  }

  void _onSubmit() async {
    final isCorrect = ListEquality().equals(selectedWords, widget.correctOrder);
    setState(() {
      submitted = true;
    });
    if (!isCorrect) {
      final prefs = await SharedPreferences.getInstance();
      final wrongAnswersService = WrongAnswersService(prefs, widget.authService);
      await wrongAnswersService.saveWrongAnswer(
        WrongAnswer(
          question: 'Собери предложение',
          userAnswer: selectedWords.join(' '),
          correctAnswer: widget.correctOrder.join(' '),
          lessonId: 0, 
        ),
      );
    }
    widget.onSubmit(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Расставьте слова в правильном порядке',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Нажимайте на слова чтобы составить предложение',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.audio != null && widget.audio['body'] != null && widget.audio['body'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: _ShuffleAudioButton(base64Audio: widget.audio['body']),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue[50]?.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ваше предложение:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (selectedWords.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
                        onPressed: _onReset,
                        tooltip: 'Сбросить',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (selectedWords.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Нажмите на слова ниже чтобы составить предложение',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.blue[300],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (selectedWords.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: selectedWords
                        .map((w) => _ShuffleWordChip(
                              text: w,
                              color: widget.lessonColor,
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Доступные слова:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.blueGrey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (availableWords.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Все слова использованы',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (availableWords.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableWords
                        .map((w) => _ShuffleWordChip(
                              text: w,
                              color: Colors.grey[200]!,
                              onTap: () => _onWordTap(w),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                widget.words.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < selectedWords.length
                        ? widget.lessonColor
                        : Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${selectedWords.length} / ${widget.words.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _AnimatedScaleButton(
              onTap: selectedWords.length == widget.words.length ? _onSubmit : null,
              backgroundColor: selectedWords.length == widget.words.length
                  ? widget.lessonColor
                  : Colors.grey[300]!,
              foregroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedWords.length == widget.words.length)
                    const Icon(Icons.check, color: Colors.white),
                  if (selectedWords.length == widget.words.length)
                    const SizedBox(width: 8),
                  Text(
                    selectedWords.length == widget.words.length
                        ? 'ПРОВЕРИТЬ'
                        : 'РАССТАВЬТЕ ВСЕ СЛОВА',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShuffleWordChip extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _ShuffleWordChip({
    required this.text,
    required this.color,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: onTap != null ? Colors.blueGrey[900] : Colors.blueGrey[700],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _ShuffleAudioButton extends StatefulWidget {
  final String base64Audio;
  const _ShuffleAudioButton({required this.base64Audio, Key? key}) : super(key: key);

  @override
  State<_ShuffleAudioButton> createState() => _ShuffleAudioButtonState();
}

class _ShuffleAudioButtonState extends State<_ShuffleAudioButton> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isInited = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _init();
    } else {
      _isInited = true;
    }
  }

  Future<void> _init() async {
    await _player.openPlayer();
    setState(() { _isInited = true; });
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _player.closePlayer();
    }
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() { _isPlaying = true; });
    if (kIsWeb) {
      final src = 'data:audio/mpeg;base64,${widget.base64Audio}';
      final audio = html.AudioElement(src);
      audio.onEnded.listen((_) {
        setState(() { _isPlaying = false; });
      });
      audio.onError.listen((_) {
        setState(() { _isPlaying = false; });
      });
      audio.play();
    } else {
      final bytes = base64Decode(widget.base64Audio);
      await _player.startPlayer(
        fromDataBuffer: bytes,
        codec: Codec.aacMP4,
        whenFinished: () {
          setState(() { _isPlaying = false; });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isInited && !_isPlaying ? _play : null,
        icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
        label: Text(_isPlaying ? 'Воспроизведение...' : 'Воспроизвести аудио'),
      ),
    );
  }
} 