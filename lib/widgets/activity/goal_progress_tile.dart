import 'package:flutter/material.dart';
import '../../theme/activity_theme.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ActivityTheme.cardBackground,
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ActivityTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                percentageText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remainingText,
            style: const TextStyle(
              fontSize: 12,
              color: ActivityTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
