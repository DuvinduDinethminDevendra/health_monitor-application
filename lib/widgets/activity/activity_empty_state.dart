import 'package:flutter/material.dart';
import '../../theme/activity_theme.dart';

class ActivityEmptyState extends StatelessWidget {
  final String message;
  final String subMessage;

  const ActivityEmptyState({
    super.key,
    this.message = 'No activities found',
    this.subMessage = 'Start moving to see your progress here.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ActivityTheme.primaryBlue.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run,
                size: 64,
                color: ActivityTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ActivityTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: const TextStyle(
                fontSize: 14,
                color: ActivityTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
