import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../models/health_log.dart';

class ProgressLineChart extends StatelessWidget {
  final List<HealthLog> logs;

  const ProgressLineChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.withAlpha(150)),
            const SizedBox(height: 16),
            Text(
              'Log one more entry to\ngenerate your trend graph!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // The logs from DB are usually newest first (descending).
    // A chart needs oldest first (ascending) to draw left to right.
    final reversedLogs = logs.reversed.toList();

    final spots = reversedLogs.map((log) {
      final date = DateTime.parse(log.date);
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), log.bmi);
    }).toList();

    final minBmi = spots.map((e) => e.y).reduce(math.min);
    final maxBmi = spots.map((e) => e.y).reduce(math.max);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x05000000), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: LineChart(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutQuart,
        LineChartData(
          minY: math.min(15.0, minBmi - 5),
          maxY: math.max(40.0, maxBmi + 5),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? Colors.white : const Color(0xFF1E293B),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                      touchedSpot.x.toInt());
                  return LineTooltipItem(
                    '${touchedSpot.y.toStringAsFixed(1)}\n',
                    TextStyle(
                      color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat('MMM dd').format(date),
                        style: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    strokeWidth: 4,
                    dashArray: [8, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: const Color(0xFF0D9488),
                        strokeWidth: 3,
                        strokeColor: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: _calculateDateInterval(spots),
                getTitlesWidget: (value, meta) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      DateFormat('MMM dd').format(date),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 10 != 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 18.5,
                color: Colors.orange.withValues(alpha: 0.2),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.withValues(alpha: 0.5)),
                  labelResolver: (line) => 'Healthy Min',
                ),
              ),
              HorizontalLine(
                y: 25.0,
                color: Colors.red.withValues(alpha: 0.2),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.withValues(alpha: 0.5)),
                  labelResolver: (line) => 'Overweight',
                ),
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0D9488),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF0D9488),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.15),
                    const Color(0xFF0D9488).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDateInterval(List<FlSpot> spots) {
    if (spots.length <= 1) return 1;
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final diff = maxX - minX;
    
    // Attempt to show 3-4 labels max to avoid overlap
    final targetLabels = 3;
    final interval = diff / targetLabels;
    return interval > 0 ? interval : 1;
  }
}
