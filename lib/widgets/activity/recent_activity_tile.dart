import 'package:flutter/material.dart';
import '../../theme/activity_theme.dart';
import '../../theme/app_theme.dart';

class RecentActivityTile extends StatelessWidget {
  final String date;
  final String type;
  final String value;
  final String duration;
  final String? calories;
  final bool isSynced;
  final VoidCallback? onDelete;

  const RecentActivityTile({
    super.key,
    required this.date,
    required this.type,
    required this.value,
    required this.duration,
    this.calories,
    required this.isSynced,
    this.onDelete,
  });

  IconData _getIcon() {
    switch (type.toLowerCase()) {
      case 'steps':
      case 'walking':
        return Icons.directions_walk;
      case 'workout':
      case 'gym':
        return Icons.fitness_center;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  Color _getColor() {
    switch (type.toLowerCase()) {
      case 'steps':
      case 'walking':
        return ActivityTheme.primaryBlue;
      case 'workout':
      case 'gym':
        return ActivityTheme.error;
      case 'running':
        return ActivityTheme.warning;
      case 'cycling':
        return ActivityTheme.tealAccent;
      case 'yoga':
        return const Color(0xFFAB47BC); // Purple
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MatteCard(
        padding: EdgeInsets.zero,
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(_getIcon(), color: color),
        ),
        title: Text(
          type[0].toUpperCase() + type.substring(1),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppTheme.sapphire,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '$value • $duration min',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppTheme.heather,
              ),
            ),
            if (calories != null) ...[
              SizedBox(width: 4),
              Text(
                '• $calories kcal',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppTheme.heather,
                ),
              ),
            ]
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppTheme.heather,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  size: 14,
                  color: isSynced ? ActivityTheme.success : ActivityTheme.warning,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, size: 16, color: ActivityTheme.error),
                  )
                ]
              ],
            )
          ],
        ),
      ),
      ),
    );
  }
}
