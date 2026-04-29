import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/activity_theme.dart';

class StepProgressCard extends StatelessWidget {
  final int currentSteps;
  final int goalSteps;

  const StepProgressCard({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = goalSteps > 0 ? (currentSteps / goalSteps) : 0.0;
    final double clampedPercentage = percentage.clamp(0.0, 1.0);
    final int remaining = max(0, goalSteps - currentSteps);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: 200,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(200, 160),
                  painter: _SemiCircleProgressPainter(
                    progress: clampedPercentage,
                    backgroundColor: Colors.grey.withAlpha(30),
                    progressColor: ActivityTheme.primaryBlue,
                    strokeWidth: 16,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk, color: ActivityTheme.primaryBlue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      currentSteps.toString(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Goal: $goalSteps',
                      style: TextStyle(
                        fontSize: 14,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressDetail(context, '${(clampedPercentage * 100).toInt()}%', 'Completed'),
              Container(width: 1, height: 30, color: Colors.grey.withAlpha(50), margin: const EdgeInsets.symmetric(horizontal: 24)),
              _buildProgressDetail(context, remaining.toString(), 'Remaining'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressDetail(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _SemiCircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _SemiCircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      backgroundPaint,
    );

    // Draw progress
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
