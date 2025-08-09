import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pomodoro_timer_model.dart';
import 'screens/main_screen.dart';
import 'language_provider.dart';
import 'services/notification_service.dart';

enum AppThemeMode { light, dark }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;
  ThemeMode get themeMode =>
      _mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    if (kIsWeb) {
      // Use in-memory only for web (no persistence)
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('theme_mode');
    if (str == 'dark') {
      _mode = AppThemeMode.dark;
    } else {
      _mode = AppThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        mode == AppThemeMode.dark ? 'dark' : 'light',
      );
    }
    if (hasListeners) notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 알림 서비스 초기화 (웹이 아닌 경우에만)
  if (!kIsWeb) {
    await NotificationService.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PomodoroTimerModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 글로벌 스캐폴드 메신저 키
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final lightTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        );
        final darkTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(
            0xFF18191A,
          ), // Apple-style dark charcoal
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF18191A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        );
        return MaterialApp(
          title: 'Study Planner',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          // SystemContextMenu 에러 방지
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
