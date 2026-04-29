import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/health_tips_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/activity_provider.dart';
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
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, authService, _) => MaterialApp(
          title: 'Health Monitor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: authService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: authService.isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen(),
        ),
      ),
    );
  }
}
