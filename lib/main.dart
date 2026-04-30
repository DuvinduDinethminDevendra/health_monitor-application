import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
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
import 'theme/app_theme.dart';
import 'package:health_monitor/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Edge-to-Edge support
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
  ));

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
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => HealthLogProvider()),

      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Health Monitor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: authService.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            locale: authService.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: authService.isLoggedIn
                ? const DashboardScreen()
                : const LoginScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/health-tips': (context) => const HealthTipsScreen(),
              '/charts': (context) => const ChartsScreen(),
              '/reminders': (context) => const RemindersScreen(),
            },
          );
        },
      ),
    );
  }
}
