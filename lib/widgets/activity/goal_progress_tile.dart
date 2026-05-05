import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class GoalProgressTile extends StatelessWidget {
  final String title;
  final double progress; // 0.0 to 1.0
  final String remainingText;
  final String percentageText;
  final IconData icon;
  final Color color;

  const GoalProgressTile({
    super.key,
    required this.title,
    required this.progress,
    required this.remainingText,
    required this.percentageText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MatteCard(
        padding: const EdgeInsets.all(16),
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.sapphire,
                  ),
                ),
              ),
              Text(
                percentageText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.scooter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.scooter.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.scooter),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            remainingText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppTheme.heather,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
