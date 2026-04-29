import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/health_tips_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/health_log_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_tips_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/reminders_screen.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCZY-5wkEEifTbIW0Fa9WgZCmgh0mDvKMY',
        authDomain: 'health-tracker-app-deffb.firebaseapp.com',
        appId: '1:127072635312:web:80697f9c6c45fd7eedae75',
        messagingSenderId: '127072635312',
        projectId: 'health-tracker-app-deffb',
        storageBucket: 'health-tracker-app-deffb.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const HealthMonitorApp());
}

class HealthMonitorApp extends StatelessWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => HealthTipsProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        ChangeNotifierProvider(create: (_) => HealthLogProvider()),
      ],
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
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.isLoggedIn
                ? const DashboardScreen()
                : const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/health-tips': (context) => const HealthTipsScreen(),
          '/charts': (context) => const ChartsScreen(),
          '/reminders': (context) => const RemindersScreen(),
        },
      ),
    );
  }
}
