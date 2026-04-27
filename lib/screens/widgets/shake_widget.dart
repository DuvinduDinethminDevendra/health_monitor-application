import 'package:flutter/material.dart';
import 'dart:math';

class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeOffset = 8,
    this.shakeCount = 3,
    this.shakeDuration = const Duration(milliseconds: 400),
  });

  final Widget child;
  final double shakeOffset;
  final int shakeCount;
  final Duration shakeDuration;

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.shakeDuration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    if (_controller.isAnimating) return;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sineValue = sin(widget.shakeCount * 2 * pi * _controller.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
