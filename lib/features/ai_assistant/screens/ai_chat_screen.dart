import 'package:flutter/material.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/wrong_answers_service.dart';
import '../../../core/models/wrong_answer.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/chat_history_service.dart';
import '../../../features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatScreen extends StatefulWidget {
  final WrongAnswersService wrongAnswersService;

  const AIChatScreen({
    required this.wrongAnswersService,
    super.key,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  List<WrongAnswer>? _wrongAnswers;
  WrongAnswer? _selectedAnswer;
  bool _isAITyping = false;
  late ChatHistoryService _chatHistoryService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    _chatHistoryService = ChatHistoryService(prefs, authService);
    
    final answers = await widget.wrongAnswersService.getWrongAnswers();
    setState(() {
      _wrongAnswers = answers;
    });
    
    final history = await _chatHistoryService.getMessages();
    if (history.isNotEmpty) {
      setState(() {
        _messages.addAll(history.map((msg) => Message(
          text: msg.text,
          isUser: msg.isUser,
        )));
      });
      _scrollToBottom();
      return;
    }

    print('Загружено ошибок: ${answers.length}');
    
    if (answers.isEmpty) {
      _addMessage(
        'У вас пока нет сохраненных ошибок для работы. Пройдите несколько уроков, и я помогу вам разобрать ваши ошибки.',
        false,
      );
    } else {
      _addMessage(
        'У вас есть новые ошибки для разбора! Над каким вопросом хотите поработать?\n\n' +
            answers.asMap().entries.map((entry) => 
              '${entry.key + 1}. ${entry.value.question}').join('\n'),
        false,
      );
    }
  }

  void _addMessage(String text, bool isUser) {
    final message = Message(text: text, isUser: isUser);
    setState(() {
      _messages.add(message);
    });
    _chatHistoryService.saveMessage(ChatMessage(
      text: text,
      isUser: isUser,
    ));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(text, true);
    _messageController.clear();

    if (_wrongAnswers != null && _wrongAnswers!.isNotEmpty) {
      final numberMatch = RegExp(r'\d+').firstMatch(text);
      if (numberMatch != null) {
        final number = int.parse(numberMatch.group(0)!);
        if (number > 0 && number <= _wrongAnswers!.length) {
          await _handleSelectedAnswer(number - 1);
          return;
        }
      }

      final lowerText = text.toLowerCase();
      int? foundIndex;
      
      for (int i = 0; i < _wrongAnswers!.length; i++) {
        final answer = _wrongAnswers![i];
        if (lowerText.contains(answer.correctAnswer.toLowerCase()) || 
            lowerText.contains(answer.userAnswer.toLowerCase()) ||
            lowerText.contains(answer.question.toLowerCase())) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex != null) {
        await _handleSelectedAnswer(foundIndex);
        return;
      }
      
      _addMessage(
        'Не могу найти такой вопрос. Пожалуйста, выберите номер вопроса из списка или напишите часть вопроса/ответа.',
        false,
      );
    }
  }

  Future<void> _handleSelectedAnswer(int index) async {
    _selectedAnswer = _wrongAnswers![index];
    
    setState(() {
      _isAITyping = true;
      _messages.add(Message(text: '', isUser: false, isTyping: true));
    });
    _scrollToBottom();
    
    final answer = await AIService().getExplanation(
      _selectedAnswer!.question,
      _selectedAnswer!.userAnswer,
    );
    
    await widget.wrongAnswersService.clearWrongAnswers();
    _wrongAnswers!.removeAt(index);
    for (var wrongAnswer in _wrongAnswers!) {
      await widget.wrongAnswersService.saveWrongAnswer(wrongAnswer);
    }
    
    setState(() {
      _isAITyping = false;
      _messages.removeLast(); 
    });
    
    _addMessage(answer, false);
    

    if (_wrongAnswers!.isNotEmpty) {
      _addMessage(
        'Остались следующие вопросы для разбора:\n\n' +
            _wrongAnswers!.asMap().entries.map((entry) => 
              '${entry.key + 1}. ${entry.value.question}').join('\n'),
        false,
      );
    } else {
      _addMessage(
        'Поздравляю! Мы разобрали все ошибки. Продолжайте учиться, и если появятся новые вопросы, я помогу вам их разобрать.',
        false,
      );
    }
  }

  Widget _buildMessage(Message message) {
    return AnimatedMessageItem(
      message: message,
      child: _buildMessageContent(message),
    );
  }

  Widget _buildMessageContent(Message message) {
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 64, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDots(),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          message.isUser ? 64 : 16,
          4,
          message.isUser ? 16 : 64,
          4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF6B73FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 40,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: _TypingDot(delay: Duration(milliseconds: index * 300)),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Работа над ошибками',
          style: TextStyle(color: Color(0xFF1A1A1A)),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.blue.shade400,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Обновить историю',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вы уверены, что хотите обновить историю чата?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Это действие нельзя будет отменить.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _chatHistoryService.clearHistory();
                                setState(() {
                                  _messages.clear();
                                });
                                _initializeServices();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Обновить',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    backgroundColor: Colors.white,
                    elevation: 8,
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isAITyping,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Введите сообщение...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _handleMessage(_messageController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B73FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
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

class Message {
  final String text;
  final bool isUser;
  final bool isTyping;

  Message({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}

class _TypingDot extends StatefulWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(widget.delay, () {
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedMessageItem extends StatefulWidget {
  final Message message;
  final Widget child;

  const AnimatedMessageItem({
    required this.message,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<AnimatedMessageItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<double>(
      begin: widget.message.isUser ? 20.0 : -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: widget.message.isUser 
                  ? Alignment.centerRight 
                  : Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
} 