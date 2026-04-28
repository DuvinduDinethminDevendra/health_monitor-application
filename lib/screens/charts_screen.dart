import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repositories/activity_repository.dart';
import '../repositories/health_log_repository.dart';
import '../repositories/goal_repository.dart';
import '../services/auth_service.dart';
import '../models/activity.dart';
import '../models/health_log.dart';
import '../models/goal.dart';

class ChartsScreen extends StatefulWidget {
  final int initialIndex;
  const ChartsScreen({super.key, this.initialIndex = 0});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Activity> _activities = [];
  List<HealthLog> _healthLogs = [];
  List<Goal> _goals = [];
  final GoalRepository _goalRepo = GoalRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final startDate =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
    final endDate = DateFormat('yyyy-MM-dd').format(now);

    final activities = await ActivityRepository()
        .getActivitiesByDateRange(userId, startDate, endDate);
    final healthLogs = await HealthLogRepository()
        .getLogsByDateRange(userId, startDate, endDate);
    final goals = await _goalRepo.getGoalsByUser(userId);

    if (!mounted) return;
    setState(() {
      _activities = activities;
      _healthLogs = healthLogs;
      _goals = goals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Charts'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Activities'),
            Tab(text: 'BMI Trend'),
            Tab(text: 'Goal Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityChart(),
                _buildBmiChart(),
                _buildGoalInsights(),
              ],
            ),
    );
  }

  // --- Member 3 Feature: Advanced Predictive Insights UI ---
  Widget _buildGoalInsights() {
    if (_goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals set yet.\nAdd goals to see your predictive insights!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final List<Color> palette = [
      const Color(0xFF1A73E8), // Blue
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF43A047), // Green
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFE53935), // Red
      const Color(0xFF00ACC1), // Cyan
    ];

    final dailyGoals = _goals.where((g) {
      final cat = g.category.toLowerCase();
      return cat == 'sleep' || cat == 'water' || cat == 'diet' || cat.contains('(daily)');
    }).toList();

    final cumulativeGoals = _goals.where((g) {
      final cat = g.category.toLowerCase();
      return !(cat == 'sleep' || cat == 'water' || cat == 'diet' || cat.contains('(daily)'));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cumulativeGoals.isNotEmpty) ...[
            const Text(
              'Cumulative Goals (Completion %)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100, // Percentage
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final goal = cumulativeGoals[groupIndex];
                        return BarTooltipItem(
                          '${goal.title}\n${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < cumulativeGoals.length) {
                            final title = cumulativeGoals[idx].title;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                title.length > 8 ? '${title.substring(0, 8)}...' : title,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(cumulativeGoals.length, (index) {
                    final goal = cumulativeGoals[index];
                    double percent = 0;
                    if (goal.targetValue > 0) {
                      percent = (goal.currentValue / goal.targetValue) * 100;
                    }
                    if (percent > 100) percent = 100;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percent,
                          color: palette[index % palette.length],
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (dailyGoals.isNotEmpty) ...[
            const Text(
              'Daily Goals (Weekly Trend)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...dailyGoals.asMap().entries.map((entry) {
              final index = entry.key;
              final goal = entry.value;
              final color = palette[(cumulativeGoals.length + index) % palette.length];

              // --- Link real Activity Data for the last 30 days ---
              final typeMatch = goal.baseType;
              
              final goalActivities = _activities.where((a) {
                return a.type.toLowerCase() == typeMatch;
              }).toList();

              final now = DateTime.now();
              final List<FlSpot> spots = [];
              double maxAchieved = 0.0;

              for (int i = 0; i < 30; i++) {
                final targetDate = now.subtract(Duration(days: 29 - i));
                final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
                
                final daySum = goalActivities
                    .where((a) => a.date.startsWith(dateStr))
                    .fold(0.0, (sum, a) => sum + a.value);
                
                if (daySum > maxAchieved) maxAchieved = daySum;
                spots.add(FlSpot(i.toDouble(), daySum));
              }

              // We no longer need the math.max() hack because _updateProgress in goals_screen.dart 
              // now natively inserts an Activity record for manual updates. 
              // This guarantees the 'daySum' is permanently and perfectly accurate on the exact date!
              
              // Set minimum Y height to the target value
              final double maxY = maxAchieved > goal.targetValue ? maxAchieved : goal.targetValue;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${goal.title} (${goal.unit})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.fromLTRB(10, 15, 20, 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 29,
                        minY: 0,
                        maxY: maxY > 0 ? maxY : 10,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final spotDate = now.subtract(Duration(days: 29 - spot.x.toInt()));
                                final dateStr = DateFormat('MMM dd').format(spotDate);
                                return LineTooltipItem(
                                  '$dateStr\n${spot.y.toStringAsFixed(1)} ${goal.unit}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true, 
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goal.targetValue,
                              color: Colors.redAccent.withOpacity(0.6),
                              strokeWidth: 1.5,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (line) => 'Goal',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                              ),
                            )
                          ],
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 6,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) return const Text('');
                                final daysAgo = 29 - value.toInt();
                                final date = now.subtract(Duration(days: daysAgo));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    daysAgo == 0 ? 'Today' : DateFormat('MM/dd').format(date), 
                                    style: const TextStyle(fontSize: 9, color: Colors.grey)
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, 
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey));
                              }
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) => spot.x == 29 || spot.y > 0,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          ],

          const SizedBox(height: 16),
          const Text(
            'Predictive Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._goals.map((goal) {
            // Premium Category Mappings (Reuse Goal Screen Aesthetic)
            IconData watermarkIcon = Icons.flag;
            Color cardColor = Colors.white;
            Color accentColor = const Color(0xFF1A73E8);

            final category = goal.category.toLowerCase();
            if (category.contains('sleep')) {
              watermarkIcon = Icons.nights_stay;
              cardColor = const Color(0xFFE8EAF6);
              accentColor = const Color(0xFF3F51B5);
            } else if (category.contains('water')) {
              watermarkIcon = Icons.water_drop;
              cardColor = const Color(0xFFE1F5FE);
              accentColor = const Color(0xFF0288D1);
            } else if (category.contains('step') || category.contains('walk')) {
              watermarkIcon = Icons.directions_run;
              cardColor = const Color(0xFFE8F5E9);
              accentColor = const Color(0xFF2E7D32);
            } else if (category.contains('diet') || category.contains('food')) {
              watermarkIcon = Icons.restaurant;
              cardColor = const Color(0xFFFFF3E0);
              accentColor = const Color(0xFFEF6C00);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Watermark
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Icon(
                        watermarkIcon,
                        size: 100,
                        color: accentColor.withOpacity(0.07),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  goal.category.toUpperCase(),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<String>(
                            future: _goalRepo.getPredictiveInsight(goal.id!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const LinearProgressIndicator();
                              }
                              final insight = snapshot.data ?? 'Calculating...';
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accentColor.withOpacity(0.1)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.auto_graph, color: accentColor, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        insight,
                                        style: TextStyle(
                                          color: accentColor.withOpacity(0.9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No activity data for charts',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Log some activities to see trends',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    // Group activities by unique types to create a 30-day timeline for EACH type
    final types = _activities.map((a) => a.type).toSet().toList();
    final now = DateTime.now();

    final palette = [
      const Color(0xFF1A73E8),
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
      const Color(0xFF00BFA5),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFF3949AB),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Timeline (Last 30 Days)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...types.asMap().entries.map((entry) {
            final type = entry.value;
            final color = palette[entry.key % palette.length];
            
            final typeActivities = _activities.where((a) => a.type == type).toList();
            final List<BarChartGroupData> barGroups = [];
            double maxY = 0.0;

            // Pass 1: Pre-calculate true maxY
            for (int i = 0; i < 30; i++) {
              final targetDate = now.subtract(Duration(days: 29 - i));
              final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
              final daySum = typeActivities
                  .where((a) => a.date.startsWith(dateStr))
                  .fold(0.0, (sum, a) => sum + a.value);
              if (daySum > maxY) maxY = daySum;
            }

            final chartMaxY = maxY > 0 ? maxY : 10.0;

            // Pass 2: Build bars with consistent bounds
            for (int i = 0; i < 30; i++) {
              final targetDate = now.subtract(Duration(days: 29 - i));
              final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
              
              final daySum = typeActivities
                  .where((a) => a.date.startsWith(dateStr))
                  .fold(0.0, (sum, a) => sum + a.value);
              
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: daySum,
                      color: color,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: chartMaxY,
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                )
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type[0].toUpperCase()}${type.substring(1)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (rod.toY == 0) return null;
                            final daysAgo = 29 - group.x.toInt();
                            final date = now.subtract(Duration(days: daysAgo));
                            return BarTooltipItem(
                              '${DateFormat('MMM dd').format(date)}\n${rod.toY.toStringAsFixed(1)}',
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
                            interval: 6,
                            getTitlesWidget: (value, meta) {
                              if (value % 6 != 0 && value != 29) return const Text('');
                              final daysAgo = 29 - value.toInt();
                              final date = now.subtract(Duration(days: daysAgo));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  daysAgo == 0 ? 'Today' : DateFormat('MM/dd').format(date), 
                                  style: const TextStyle(fontSize: 10)
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBmiChart() {
    if (_healthLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No BMI data for charts',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Log your weight & height to see trends',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    final spots = _healthLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.bmi);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BMI Trend (Last 30 Days)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final log = _healthLogs[spot.x.toInt()];
                        return LineTooltipItem(
                          'BMI: ${log.bmi}\n${log.date}',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _healthLogs.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _healthLogs[idx].date.substring(5),
                              style: const TextStyle(fontSize: 10),
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
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00BFA5),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF00BFA5),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00BFA5).withAlpha(30),
                    ),
                  ),
                ],
                // Reference lines for BMI categories
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 18.5,
                      color: Colors.orange.withAlpha(100),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Underweight',
                        style:
                            TextStyle(fontSize: 10, color: Colors.orange[300]),
                      ),
                    ),
                    HorizontalLine(
                      y: 25,
                      color: Colors.orange.withAlpha(100),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Overweight',
                        style:
                            TextStyle(fontSize: 10, color: Colors.orange[300]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // BMI category legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBmiCategory('< 18.5', 'Underweight', Colors.orange),
              _buildBmiCategory('18.5-25', 'Normal', const Color(0xFF00BFA5)),
              _buildBmiCategory('25-30', 'Overweight', Colors.orange),
              _buildBmiCategory('> 30', 'Obese', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCategory(String range, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(range,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
