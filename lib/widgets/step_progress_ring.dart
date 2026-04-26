import 'dart:math';
import 'package:flutter/material.dart';

class StepProgressRing extends StatefulWidget {
  final double progress;
  final int stepCount;
  final int goal;
  final double size;

  const StepProgressRing({
    super.key,
    required this.progress,
    required this.stepCount,
    required this.goal,
    this.size = 180,
  });

  @override
  State<StepProgressRing> createState() => _StepProgressRingState();
}

class _StepProgressRingState extends State<StepProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(StepProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _StepProgressRingPainter(
            progress: widget.progress * _animation.value,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.stepCount.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'steps',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepProgressRingPainter extends CustomPainter {
  final double progress;

  _StepProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 7; // - half stroke width

    // Background arc (grey)
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc (blue/green)
    final fgPaint = Paint()
      ..color = progress >= 1.0 ? const Color(0xFF00BFA5) : const Color(0xFF1A73E8)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start angle: -pi/2 (top)
    // Sweep angle: progress * 2*pi
    final sweepAngle = min(progress, 1.0) * 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StepProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
