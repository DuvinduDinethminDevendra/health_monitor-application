import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/health_tips_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/widgets/page_transitions.dart';

void main() async {
  // Required for plugin initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop support (Windows/macOS/Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification initialization failed: \$e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const HealthMonitorApp(),
    ),
  );
}

class HealthMonitorApp extends StatelessWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF1A73E8),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final isLoggedIn = authService.isLoggedIn;
          
          // Route guard
          if (!isLoggedIn && settings.name != '/login' && settings.name != '/register') {
            return FadePageRoute(
              settings: settings,
              child: const LoginScreen(),
            );
          }

          Widget page;
          switch (settings.name) {
            case '/login':
              page = const LoginScreen();
              break;
            case '/register':
              page = const RegisterScreen();
              break;
            case '/dashboard':
              page = const DashboardScreen();
              break;
            case '/health-tips':
              page = const HealthTipsScreen();
              break;
            case '/charts':
              page = const ChartsScreen();
              break;
            case '/reminders':
              page = const RemindersScreen();
              break;
            case '/':
            default:
              page = isLoggedIn ? const DashboardScreen() : const LoginScreen();
              break;
          }

          if (settings.name == '/dashboard' || settings.name == '/login' || settings.name == '/') {
            return FadePageRoute(settings: settings, child: page);
          }
          return SlidePageRoute(settings: settings, child: page);
        },
      );
  }
}
