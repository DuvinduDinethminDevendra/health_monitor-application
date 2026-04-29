import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/health_log.dart';

class LiquidHealthIndicator extends StatefulWidget {
  final HealthLog? latestLog;
  final HealthLog? comparisonLog;

  const LiquidHealthIndicator({super.key, this.latestLog, this.comparisonLog});

  @override
  State<LiquidHealthIndicator> createState() => _LiquidHealthIndicatorState();
}

class _LiquidHealthIndicatorState extends State<LiquidHealthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latestLog == null) return const SizedBox.shrink();

    final log = widget.latestLog!;
    final bmi = log.bmi;
    
    // Calculate level based on BMI range 15 (empty) to 35 (full)
    double level = (bmi - 15) / (35 - 15);
    level = level.clamp(0.05, 0.95);

    final color = _getLiquidColor(bmi);

    double? compLevel;
    Color? compColor;
    if (widget.comparisonLog != null) {
      final compBmi = widget.comparisonLog!.bmi;
      compLevel = (compBmi - 15) / (35 - 15);
      compLevel = compLevel.clamp(0.05, 0.95);
      compColor = _getLiquidColor(compBmi);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black26 : const Color(0x08000000), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.comparisonLog != null ? 'COMPARISON ACTIVE' : 'HEALTH STATUS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: widget.comparisonLog != null ? const Color(0xFF0D9488) : (isDark ? Colors.white60 : const Color(0xFF94A3B8)))),
              Icon(Icons.waves, size: 16, color: widget.comparisonLog != null ? const Color(0xFF0D9488) : (isDark ? Colors.white38 : const Color(0xFFCBD5E1))),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Tank
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9), width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(62),
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _MixedWavePainter(
                            animationValue: _waveController.value,
                            color: color,
                            level: level,
                            compColor: compColor,
                            compLevel: compLevel,
                          ),
                          child: Container(),
                        );
                      },
                    ),
                  ),
                ),
                
                // Reflection overlay
                IgnorePointer(
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.1),
                        ],
                        stops: const [0.1, 0.5, 0.9],
                      ),
                    ),
                  ),
                ),

                // Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'BMI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : const Color(0xFF1E293B).withOpacity(0.5),
                      ),
                    ),
                    if (widget.comparisonLog != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PREV: ${widget.comparisonLog!.bmi.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            log.bmiCategory.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLiquidColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return const Color(0xFF0D9488);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _MixedWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double level;
  final Color? compColor;
  final double? compLevel;

  _MixedWavePainter({
    required this.animationValue,
    required this.color,
    required this.level,
    this.compColor,
    this.compLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Comparison Wave if exists (The "Ghost" background wave)
    if (compLevel != null && compColor != null) {
      // Comparison wave is slower and has a different phase
      _drawWave(canvas, size, compLevel!, compColor!.withOpacity(0.4), animationValue * 0.8, true);
    }

    // 2. Draw Main Wave
    // We reduce opacity if comparison is active to allow "mixing"
    final mainOpacity = compLevel != null ? 0.6 : 0.8;
    _drawWave(canvas, size, level, color.withOpacity(mainOpacity), animationValue, false);

    // 3. Draw a very thin "Surface Gloss" for both
    _drawWave(canvas, size, level, Colors.white.withOpacity(0.15), animationValue, true);
    if (compLevel != null) {
      _drawWave(canvas, size, compLevel!, Colors.white.withOpacity(0.1), animationValue * 0.8, true);
    }
  }

  void _drawWave(Canvas canvas, Size size, double lvl, Color clr, double anim, bool isSecondary) {
    final paint = Paint()..color = clr;
    
    // Gradient only for the main wave to give depth
    if (!isSecondary && compLevel == null) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [clr.withOpacity(0.8), clr],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final path = Path();
    final yOffset = size.height * (1 - lvl);
    // Make comparison wave slightly taller so it's visible behind/in front
    final waveHeight = isSecondary ? 10.0 : 7.0;
    const waveFrequency = 1.6;

    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      final y = yOffset +
          math.sin((x / size.width * waveFrequency * 2 * math.pi) + (anim * 2 * math.pi)) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MixedWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.level != level ||
        oldDelegate.compLevel != compLevel;
  }
}
