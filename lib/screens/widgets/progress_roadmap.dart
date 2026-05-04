import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/health_log.dart';

class ProgressRoadmap extends StatelessWidget {
  final List<HealthLog> logs;

  const ProgressRoadmap({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    // Show the last 5-7 logs as a "Journey"
    final journeyLogs = logs.take(7).toList().reversed.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 24),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 20),
                SizedBox(width: 8),
                Text('YOUR HEALTH JOURNEY',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B))),
              ],
            ),
          ),
          Stack(
            children: [
              // The Winding Path Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: RoadmapPathPainter(count: journeyLogs.length, isDark: isDark),
                ),
              ),
              // The Nodes
              Column(
                children: List.generate(journeyLogs.length, (index) {
                  final log = journeyLogs[index];
                  final isEven = index % 2 == 0;
                  final isLast = index == journeyLogs.length - 1;
                  
                  // Check for achievements
                  bool isRecord = false;
                  if (index > 0) {
                     final minPrev = journeyLogs.sublist(0, index).map((l) => l.weight).reduce((a, b) => a < b ? a : b);
                     if (log.weight < minPrev) isRecord = true;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (!isEven) const Spacer(),
                        _buildMilestoneNode(context, log, index, isRecord, isLast, isDark),
                        if (isEven) const Spacer(),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneNode(BuildContext context, HealthLog log, int index, bool isRecord, bool isLatest, bool isDark) {
    final bmiColor = _getBmiColor(log.bmi);
    
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // The Outer Ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                  border: Border.all(color: bmiColor.withValues(alpha: 0.2), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: bmiColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
              // The Main Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [bmiColor, bmiColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    log.weight.toStringAsFixed(0),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
              // Achievement Badge
              if (isRecord)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, size: 12, color: Colors.white),
                  ).animate().scale(delay: 500.ms).shake(),
                ),
              if (log.bmiCategory == 'Normal')
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2DD4BF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: (index * 200).ms).slideY(begin: 0.2, end: 0),
          SizedBox(height: 8),
          Text(
            DateFormat('MMM dd').format(DateTime.parse(log.date)),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : const Color(0xFF94A3B8)),
          ),
          if (isLatest)
             Container(
               margin: const EdgeInsets.only(top: 4),
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white : const Color(0xFF1E293B),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text('CURRENT', style: TextStyle(color: isDark ? const Color(0xFF1E293B) : Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
             ),
        ],
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return const Color(0xFF0D9488);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class RoadmapPathPainter extends CustomPainter {
  final int count;
  final bool isDark;

  RoadmapPathPainter({required this.count, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    final paint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Calculate vertical spacing
    const double nodeSpacing = 114.0; 
    
    for (int i = 0; i < count - 1; i++) {
      final startY = 32.0 + (i * nodeSpacing);
      final endY = 32.0 + ((i + 1) * nodeSpacing);
      
      final startX = i % 2 == 0 ? 70.0 : size.width - 70.0;
      final endX = (i + 1) % 2 == 0 ? 70.0 : size.width - 70.0;

      path.moveTo(startX, startY);
      
      // Bezier curve for the "Snake" look
      path.cubicTo(
        startX, startY + (nodeSpacing / 2),
        endX, endY - (nodeSpacing / 2),
        endX, endY,
      );
    }

    canvas.drawPath(path, paint);
    
    final dashPaint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
