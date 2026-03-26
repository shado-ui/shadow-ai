import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'models/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env file may not exist on device; API keys can be set in Settings
  }

  await DatabaseService().database;
  final db = DatabaseService();
  
  final dbTheme = await db.getSetting('app_theme');
  if (dbTheme != null && AppTheme.availableThemes.contains(dbTheme)) {
      AppState().currentTheme.value = dbTheme;
  } else {
      AppState().currentTheme.value = 'Dark';
  }
  
  if (AppState().currentTheme.value == 'Custom') {
      final customHex = await DatabaseService().getSetting('custom_theme_hex');
      if (customHex != null && customHex.isNotEmpty) {
          try {
              final val = int.parse(customHex.replaceAll('#', ''), radix: 16);
              AppTheme.customAccent = Color(0xFF000000 | val);
              AppState().currentTheme.value = 'Custom';
          } catch (_) {
              // Invalid hex value, ignore
          }
      }
  }

  // Check if user has API keys set up
  final orKey = await DatabaseService().getSetting('openrouter_key');
  final gemKey = await DatabaseService().getSetting('api_key');
  final bool needsSetup = (orKey == null || orKey.isEmpty) && (gemKey == null || gemKey.isEmpty);

  runApp(ShadowAIApp(needsSetup: needsSetup));
}

class ShadowAIApp extends StatelessWidget {
  final bool needsSetup;
  const ShadowAIApp({super.key, this.needsSetup = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState().currentTheme,
      builder: (context, themeName, child) {
        AppTheme.setTheme(themeName);
        return MaterialApp(
          title: 'Shadow AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          initialRoute: needsSetup ? '/setup' : '/home',
          routes: {
            '/setup': (context) => const SetupScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
