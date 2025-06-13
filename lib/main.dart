import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.html) 'dart:html' as html;
import 'config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/ai_service.dart';
import 'core/services/stripe_service/stripe_service.dart';
import 'features/home/screens/main_screen.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
    
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    print('Загружен файл .env');
    print('API ключ OpenAI ${apiKey != null ? "найден" : "не найден"}');
    
    final hasStripeKeys = StripeService.hasValidKeys;
    final pubKey = StripeService.publishableKey;
    final secKey = StripeService.secretKey;
    
    print('Ключи Stripe ${hasStripeKeys ? "найдены" : "не найдены"}');
    if (!hasStripeKeys) {
      print('Publishable Key: ${pubKey.isEmpty ? "отсутствует" : "найден"}');
      print('Secret Key: ${secKey.isEmpty ? "отсутствует" : "найден"}');
    }
    
    AIService().initialize();
    
    runApp(const TilimApp());
  } catch (e) {
    print('Ошибка при инициализации приложения: $e');
    rethrow;
  }
}

class TilimApp extends StatelessWidget {
  const TilimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilim App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        final basePath = uri.path;
        
        final builder = AppRouter.routes[basePath];
        
        if (builder != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: builder,
          );
        }
        
        if (kIsWeb) {
          final origin = html.window.location.origin;
          html.window.location.href = '$origin/#/main';
        }
        return MaterialPageRoute(
          builder: (context) => MainScreen(authService: AuthService()),
        );
      },
    );
  }
}
