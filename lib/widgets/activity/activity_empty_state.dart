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
              child: Icon(
                Icons.directions_run,
                size: 64,
                color: ActivityTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: 14,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
