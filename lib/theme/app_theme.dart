import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // Pallet 3 - Emerald Obsidian (Vibrant Light Mode)
  static const Color bangladeshGreen = Color(0xFF03624C);
  static const Color richBlack = Color(0xFF1F2937); // Used for text
  static const Color caribbeanGreen = Color(0xFF00DF81); // Primary Vibrant
  static const Color mountainMeadow = Color(0xFF2CC295); // Secondary
  static const Color backgroundLight = Color(0xFFF9FAFB); // Light background
  static const Color antiFlashWhite = Color(0xFFFFFFFF); // For cards
  
  static const Color emeraldGreen = Color(0xFF00DF81); 
  static const Color darkCharcoal = Color(0xFF1F2937); 
  static const Color mutedGrey = Color(0xFF6B7280); 
  static const Color warmOrange = Color(0xFFF97316); 
  static const Color skyBlue = Color(0xFF0EA5E9); 

  static const Color glassWhite = Color(0xE6FFFFFF); // Solid 90% white
  static const Color glassBorder = Color(0x33000000); // Dark border for contrast

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: caribbeanGreen,
    colorScheme: ColorScheme.light(
      primary: caribbeanGreen,
      secondary: mountainMeadow,
      surface: antiFlashWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkCharcoal,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkCharcoal, fontWeight: FontWeight.w900, letterSpacing: -1.5),
      displayMedium: TextStyle(color: darkCharcoal, fontWeight: FontWeight.w900, letterSpacing: -1),
      headlineMedium: TextStyle(color: darkCharcoal, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      bodyLarge: TextStyle(color: darkCharcoal, letterSpacing: -0.2),
      bodyMedium: TextStyle(color: darkCharcoal, letterSpacing: -0.2),
      bodySmall: TextStyle(color: mutedGrey, letterSpacing: -0.1),
    ),
    fontFamily: 'Inter',
  );

  static final ThemeData darkTheme = lightTheme; // Waiting for user choice
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.width,
    this.height,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppTheme.glassWhite,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppTheme.glassBorder,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
