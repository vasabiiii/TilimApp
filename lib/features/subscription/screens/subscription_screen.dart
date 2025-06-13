import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.html) 'dart:html' as html;
import '../../../core/services/stripe_service/stripe_service.dart';
import '../../../core/services/stripe_service/web_stripe_service.dart';
import '../../subscription/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  bool _isStripeAvailable = false;
  String? _httpsUrl;
  int? _selectedPlanIndex;

  static const List<Map<String, dynamic>> _plans = [
    {
      'duration': '1 месяц',
      'price': '2,990₸',
      'description': 'Идеально для начала',
      'discount': null,
      'priceAmount': 2990,
    },
    {
      'duration': '3 месяца',
      'price': '6,990₸',
      'description': 'Лучший баланс цены и времени',
      'discount': '22%',
      'priceAmount': 6990,
    },
    {
      'duration': '1 год',
      'price': '24,990₸',
      'description': 'Максимальная экономия',
      'discount': '30%',
      'priceAmount': 24990,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    if (!kIsWeb) return;

    try {
      await StripeService.instance.initialize();
      if (StripeService.instance is WebStripeService) {
        setState(() {
          _isStripeAvailable = (StripeService.instance as WebStripeService).isStripeAvailable();
        });
      }
    } catch (e) {
      print('Ошибка при инициализации Stripe: $e');
      setState(() {
        _isStripeAvailable = false;
      });
    }
  }

  void _redirectToHttps(String url) {
    html.window.location.href = url;
  }

  Future<void> _handlePayment(int planIndex) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _selectedPlanIndex = planIndex;
    });

    try {
      final plan = _plans[planIndex];
      final now = DateTime.now();
      DateTime expiresAt;
      if (plan['duration'].contains('год')) {
        expiresAt = DateTime(now.year + 1, now.month, now.day);
      } else if (plan['duration'].contains('месяц') && plan['duration'].contains('3')) {
        expiresAt = DateTime(now.year, now.month + 3, now.day);
      } else {
        expiresAt = DateTime(now.year, now.month + 1, now.day);
      }
      final service = SubscriptionService();
      final purchaseResult = await service.purchaseSubscription(expiresAt);
      
      if (purchaseResult && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/profile');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка успешно активирована!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при активации подписки')),
        );
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при активации подписки')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedPlanIndex = null;
        });
      }
    }
  }



  Widget _buildSubscriptionCard(int index) {
    final plan = _plans[index];
    final isSelected = index == _selectedPlanIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? const Color(0xFF2196F3).withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF1a237e),
                ),
                child: Text(plan['duration']),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF1a237e),
                    ),
                    child: Text(plan['price']),
                  ),
                  if (plan['discount'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Скидка ${plan['discount']}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.grey[800] : Colors.grey[600],
                ),
                child: Text(plan['description']),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handlePayment(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF2196F3) : const Color(0xFF1a237e),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: isSelected ? 4 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (_isLoading && _selectedPlanIndex == index)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Выбрать план',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1a237e)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Подписка',
          style: TextStyle(
            color: Color(0xFF1a237e),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Image.asset(
                    'images/tilim-pro.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a237e).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.school,
                            color: Color(0xFF1a237e),
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Text(
                'Разблокируйте весь потенциал обучения',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF1a237e),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Что входит в подписку',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.all_inclusive,
                title: 'Безлимитные уроки',
                description: 'Изучайте сколько хотите без ограничений',
              ),
              _buildFeatureItem(
                icon: Icons.smart_toy,
                title: 'ИИ ассистент',
                description: 'Персональный помощник объяснит любую тему',
              ),
              _buildFeatureItem(
                icon: Icons.support_agent,
                title: 'Поддержка 24/7',
                description: 'Быстрые ответы на ваши вопросы',
              ),
              const SizedBox(height: 32),
              const Text(
                'Выберите план',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
              const SizedBox(height: 16),
              ..._plans.asMap().entries.map((entry) => _buildSubscriptionCard(entry.key)),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Безопасная оплата через ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Stripe',
                      style: TextStyle(
                        color: Color(0xFF635BFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a237e),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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