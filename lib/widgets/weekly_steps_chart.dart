import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/step_record.dart';

class WeeklyStepsChart extends StatelessWidget {
  final List<StepRecord> weeklySteps;
  final int goal;

  const WeeklyStepsChart({
    super.key,
    required this.weeklySteps,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklySteps.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} steps',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < weeklySteps.length) {
                    final dateStr = weeklySteps[index].date;
                    final date = DateTime.parse(dateStr);
                    final dayAbbr = DateFormat('EEE').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dayAbbr,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 2000 == 0) {
                    return Text(
                      '${(value / 1000).toInt()}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2000,
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goal.toDouble(),
                color: const Color(0xFFFB8C00), // Warning Orange
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  style: const TextStyle(color: Color(0xFFFB8C00), fontSize: 10),
                  labelResolver: (line) => 'Goal',
                ),
              ),
            ],
          ),
          barGroups: weeklySteps.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isGoalMet = record.stepCount >= goal;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: record.stepCount.toDouble(),
                  color: isGoalMet ? const Color(0xFF00BFA5) : const Color(0xFF1A73E8),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    double maxSteps = goal.toDouble();
    for (var record in weeklySteps) {
      if (record.stepCount > maxSteps) {
        maxSteps = record.stepCount.toDouble();
      }
    }
    return maxSteps * 1.2; // Add 20% padding above highest bar
  }
}
