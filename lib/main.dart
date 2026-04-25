import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD0gt14d7BTZd0IWxwn3gIaJSiNMM5MjoI',
        appId: '1:127072635312:web:8c3f8367c0cc3a16edae75', // Generated generic web ID
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
      ),
    );
  }
}
