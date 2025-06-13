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
      'price': '1,020₸',
      'description': 'Идеально для начала',
      'discount': null,
      'priceAmount': 1020,
    },
    {
      'duration': '3 месяца',
      'price': '2,590₸',
      'description': 'Лучший баланс цены и времени',
      'discount': '15%',
      'priceAmount': 2590,
    },
    {
      'duration': '1 год',
      'price': '9,190₸',
      'description': 'Максимальная экономия',
      'discount': '25%',
      'priceAmount': 9190,
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
    
    if (!_isStripeAvailable) return;

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
      await service.purchaseSubscription(expiresAt);
      
      await StripeService.instance.makePayment(
        amount: plan['priceAmount'],
        currency: 'kzt',
        onPaymentResult: (stripeSuccess) {
          if (stripeSuccess && mounted) {
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        if (e is SecureConnectionException) {
          setState(() => _httpsUrl = e.httpsUrl);
          _showSecureConnectionDialog(e.message);
        }
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

  void _showSecureConnectionDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Требуется безопасное соединение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Нажмите кнопку ниже, чтобы перейти на безопасную версию сайта.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_httpsUrl != null) {
                _redirectToHttps(_httpsUrl!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Перейти на HTTPS'),
          ),
        ],
      ),
    );
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
                children: [
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                      ),
                      child: Text(plan['price']),
                    ),
                  ),
                  if (plan['discount'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Скидка ${plan['discount']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
      appBar: AppBar(
        title: const Text('Подписка'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите план подписки',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Получите полный доступ ко всем функциям приложения',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, index) => _buildSubscriptionCard(index),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedPlanIndex != null && !_isLoading
                    ? () => _handlePayment(_selectedPlanIndex!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Оформить подписку',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 