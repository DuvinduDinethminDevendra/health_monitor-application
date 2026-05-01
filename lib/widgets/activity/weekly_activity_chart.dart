import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/activity_theme.dart';
import '../../models/step_record.dart';
import '../../theme/app_theme.dart';

class WeeklyActivityChart extends StatelessWidget {
  final List<StepRecord> weeklySteps;
  final int dailyGoal;

  const WeeklyActivityChart({
    super.key,
    required this.weeklySteps,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (weeklySteps.isEmpty) {
      return MatteCard(
        height: 200,
        color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
        child: Center(
          child: Text(
            'No activity data for the last 7 days.',
            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B))),
          ),
        ),
      );
    }

    // Ensure we have exactly 7 days of data points, even if some are 0
    // The weeklySteps might be sparse from the DB.
    final today = DateTime.now();
    List<BarChartGroupData> barGroups = [];
    double maxY = dailyGoal.toDouble();
    
    // Create a map for quick lookup
    final Map<String, int> stepMap = {
      for (var record in weeklySteps) record.date: record.stepCount
    };

    int bestSteps = 0;
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final steps = stepMap[dateStr] ?? 0;
      
      if (steps > maxY) maxY = steps.toDouble();
      if (steps > bestSteps) bestSteps = steps;

      final isBest = steps == bestSteps && steps > 0;
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: steps.toDouble(),
              color: isBest ? AppTheme.scooter : AppTheme.sapphire,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY * 1.1,
                color: Colors.grey.withAlpha(20),
              ),
            ),
          ],
        ),
      );
    }

    return MatteCard(
      height: 240,
      padding: const EdgeInsets.only(top: 24, right: 16, left: 0, bottom: 16),
      color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final date = today.subtract(Duration(days: 6 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                        fontSize: 12,
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: dailyGoal > 0 ? dailyGoal.toDouble() : 10000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: value == dailyGoal ? ActivityTheme.warning.withAlpha(150) : Colors.grey.withAlpha(50),
                strokeWidth: value == dailyGoal ? 2 : 1,
                dashArray: value == dailyGoal ? [4, 4] : null,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
