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

  runApp(const HealthMonitorApp());
}

class HealthMonitorApp extends StatelessWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
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
          return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              final authService = Provider.of<AuthService>(context, listen: false);
              final isLoggedIn = authService.isLoggedIn;
              
              // Route guard
              if (!isLoggedIn && settings.name != '/login' && settings.name != '/register') {
                return const LoginScreen();
              }

              switch (settings.name) {
                case '/login':
                  return const LoginScreen();
                case '/register':
                  return const RegisterScreen();
                case '/dashboard':
                  return const DashboardScreen();
                case '/health-tips':
                  return const HealthTipsScreen();
                case '/charts':
                  return const ChartsScreen();
                case '/reminders':
                  return const RemindersScreen();
                case '/':
                default:
                  return isLoggedIn ? const DashboardScreen() : const LoginScreen();
              }
            },
          );
        },
      ),
    );
  }
}
