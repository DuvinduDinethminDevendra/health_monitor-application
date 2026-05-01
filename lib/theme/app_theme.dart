import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // Global helper for Sinhala text scaling to maintain premium aesthetics
  static double siSize(BuildContext context, double base) {
    try {
      final isSi = Localizations.localeOf(context).languageCode == 'si';
      return isSi ? base * 0.85 : base;
    } catch (_) {
      return base;
    }
  }

  // Pallet 2 - Exact Hex Codes from User Image
  static const Color scooter = Color(0xFF2F9D94);
  static const Color alabaster = Color(0xFFF7F6F2); 
  static const Color heather = Color(0xFFBCC5CC);
  static const Color blueLagoon = Color(0xFF025F67);
  static const Color sapphire = Color(0xFF063154);

  // Functional aliases
  static const Color backgroundLight = alabaster;
  static const Color backgroundDark = Color(0xFF0F172A); // Midnight Sapphire
  static const Color darkCharcoal = sapphire;
  static const Color emeraldGreen = blueLagoon;
  static const Color warmOrange = Color(0xFFF97316); 
  static const Color skyBlue = Color(0xFF0EA5E9); 
  static const Color mutedGrey = heather;
  static const Color glassWhite = Colors.white;
  static const Color caribbeanGreen = scooter;

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: alabaster,
    primaryColor: blueLagoon,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: blueLagoon,
      secondary: scooter,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: sapphire,
      error: Colors.redAccent,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: sapphire, fontWeight: FontWeight.w900, letterSpacing: -1.5),
      displayMedium: TextStyle(color: sapphire, fontWeight: FontWeight.w900, letterSpacing: -1),
      headlineMedium: TextStyle(color: sapphire, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      bodyLarge: TextStyle(color: sapphire, letterSpacing: -0.2),
      bodyMedium: TextStyle(color: sapphire, letterSpacing: -0.2),
      bodySmall: TextStyle(color: sapphire, letterSpacing: -0.1),
    ),
    fontFamily: 'Outfit',
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: scooter,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: scooter,
      secondary: blueLagoon,
      surface: Color(0xFF0A2A3F), // Solid Slate
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1.5),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      bodyLarge: TextStyle(color: Colors.white, letterSpacing: -0.2, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.white, letterSpacing: -0.2),
      bodySmall: TextStyle(color: Colors.white70, letterSpacing: -0.1),
    ),
    fontFamily: 'Outfit',
    useMaterial3: true,
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: Colors.white70,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2F9D94), width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

class MatteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;
  final double? width;
  final double? height;

  const MatteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.color,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? Colors.white.withOpacity(0.08) : Colors.white);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Keep GlassCard as an alias to MatteCard to avoid breaking build, but make it Matte
typedef GlassCard = MatteCard;
