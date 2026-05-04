import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UIUtils {
  static void showNotification(
    BuildContext context, 
    String message, {
    bool isError = false,
    bool isSuccess = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Global Premium Colors from AppTheme
    final accentColor = isError 
        ? const Color(0xFFE11D48) // Premium Rose Red
        : (isSuccess ? AppTheme.scooter : AppTheme.skyBlue);

    // Dynamic background based on theme mode
    final bgColor = isDark 
        ? const Color(0xFF1E293B) // Midnight Slate
        : Colors.white;

    final textColor = isDark ? Colors.white : AppTheme.sapphire;
    final iconColor = accentColor;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : (isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded),
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white12 : AppTheme.heather.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
