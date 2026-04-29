import 'package:flutter/material.dart';
import '../../theme/activity_theme.dart';

class ActivityLoadingSkeleton extends StatefulWidget {
  const ActivityLoadingSkeleton({super.key});

  @override
  State<ActivityLoadingSkeleton> createState() => _ActivityLoadingSkeletonState();
}

class _ActivityLoadingSkeletonState extends State<ActivityLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBox(double height, [double width = double.infinity]) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)).withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBox(160),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildBox(100)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBox(100)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBox(200),
                const SizedBox(height: 24),
                _buildBox(60),
                const SizedBox(height: 8),
                _buildBox(60),
              ],
            ),
          ),
        );
      },
    );
  }
}
