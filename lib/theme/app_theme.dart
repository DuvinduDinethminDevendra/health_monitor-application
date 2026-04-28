import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  static const Color backgroundLight = Color(0xFFFAFAF8);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color warmOrange = Color(0xFFF97316);
  static const Color skyBlue = Color(0xFF0EA5E9);
  static const Color darkCharcoal = Color(0xFF1F2937);
  static const Color mutedGrey = Color(0xFF6B7280);

  static const Color glassWhite = Color(0x99FFFFFF); // 60% white
  static const Color glassBorder = Color(0x66FFFFFF); // 40% white

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: emeraldGreen,
    colorScheme: const ColorScheme.light(
      primary: emeraldGreen,
      secondary: warmOrange,
      surface: backgroundLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkCharcoal,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkCharcoal, fontWeight: FontWeight.bold),
      displayMedium:
          TextStyle(color: darkCharcoal, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: darkCharcoal),
      bodyMedium: TextStyle(color: darkCharcoal),
      bodySmall: TextStyle(color: mutedGrey),
    ),
    fontFamily: 'Roboto',
  );
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
