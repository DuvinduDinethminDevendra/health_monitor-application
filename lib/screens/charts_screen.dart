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
import '../theme/app_theme.dart';
import 'package:health_monitor/l10n/app_localizations.dart';

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
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialIndex);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.progress, 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : AppTheme.sapphire, letterSpacing: -1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.blueLagoon,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white38 : AppTheme.sapphire.withValues(alpha: 0.4),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.activity),
                Tab(text: AppLocalizations.of(context)!.trends),
                Tab(text: AppLocalizations.of(context)!.insights),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      return cat == 'sleep' ||
          cat == 'water' ||
          cat == 'diet' ||
          cat.contains('(daily)');
    }).toList();

    final now = DateTime.now();
    final cumulativeGoals = _goals.where((g) {
      final cat = g.category.toLowerCase();
      final isCumulative = !(cat == 'sleep' ||
          cat == 'water' ||
          cat == 'diet' ||
          cat.contains('(daily)'));
      if (!isCumulative) return false;
      
      // Filter out goals where deadline has passed
      final deadline = DateTime.parse(g.deadline);
      return deadline.isAfter(now);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Goal Performance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Visual breakdown of your active health targets',
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          if (cumulativeGoals.isNotEmpty) ...[
            const Text(
              'Cumulative Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            MatteCard(
              height: 280,
              color: isDark ? const Color(0xFF0A2A3F) : AppTheme.warmOrange.withValues(alpha: 0.03),
              padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 110, // Extra space for labels
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final goal = cumulativeGoals[groupIndex];
                        final deadlineStr = DateFormat('MMM dd').format(DateTime.parse(goal.deadline));
                        return BarTooltipItem(
                          '${goal.title}\n${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}\nDeadline: $deadlineStr\n${rod.toY.toInt()}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < cumulativeGoals.length) {
                            final title = cumulativeGoals[idx].title;
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  title.length > 8 ? '${title.substring(0, 8)}...' : title,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppTheme.mutedGrey),
                                ),
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
                        reservedSize: 35,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          if (value > 100) return const Text('');
                          return Text('${value.toInt()}%',
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppTheme.mutedGrey, fontWeight: FontWeight.w500));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(cumulativeGoals.length, (index) {
                    final goal = cumulativeGoals[index];
                    double percent = (goal.targetValue > 0) ? (goal.currentValue / goal.targetValue) * 100 : 0;
                    if (percent > 100) percent = 100;
                    final color = palette[index % palette.length];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percent,
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
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
              final color =
                  palette[(cumulativeGoals.length + index) % palette.length];

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
              final double maxY = maxAchieved > goal.targetValue
                  ? maxAchieved
                  : goal.targetValue;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${goal.title} (${goal.unit})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GlassCard(
                    height: 150,
                    padding: const EdgeInsets.fromLTRB(10, 15, 20, 5),
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
                                final spotDate = now.subtract(
                                    Duration(days: 29 - spot.x.toInt()));
                                final dateStr =
                                    DateFormat('MMM dd').format(spotDate);
                                return LineTooltipItem(
                                  '$dateStr\n${spot.y.toStringAsFixed(1)} ${goal.unit}',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
                              strokeWidth: 1),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goal.targetValue,
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              strokeWidth: 1.5,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (line) => 'Goal',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 4),
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
                                final date =
                                    now.subtract(Duration(days: daysAgo));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                      daysAgo == 0
                                          ? 'Today'
                                          : DateFormat('MM/dd').format(date),
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.grey)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(),
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.grey));
                                }),
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
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) =>
                                  spot.x == 29 || spot.y > 0,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
          const SizedBox(height: 16),
          const Text(
            'Predictive Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._goals.map((goal) {
            IconData watermarkIcon = Icons.flag_rounded;
            Color accentColor = AppTheme.skyBlue;

            final category = goal.category.toLowerCase();
            if (category.contains('sleep')) {
              watermarkIcon = Icons.nights_stay_rounded;
              accentColor = AppTheme.darkCharcoal;
            } else if (category.contains('water')) {
              watermarkIcon = Icons.water_drop_rounded;
              accentColor = AppTheme.skyBlue;
            } else if (category.contains('step') || category.contains('walk')) {
              watermarkIcon = Icons.directions_run_rounded;
              accentColor = AppTheme.emeraldGreen;
            } else if (category.contains('diet') || category.contains('food')) {
              watermarkIcon = Icons.restaurant_rounded;
              accentColor = AppTheme.warmOrange;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    // Watermark
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Icon(
                        watermarkIcon,
                        size: 100,
                        color: accentColor.withValues(alpha: 0.07),
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.darkCharcoal),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
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
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.alabaster,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
                                          color: isDark ? Colors.white : accentColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activity Timeline',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your performance over the last 30 days',
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...types.asMap().entries.map((entry) {
            final type = entry.value;
            final color = palette[entry.key % palette.length];

            final typeActivities =
                _activities.where((a) => a.type == type).toList();
            final List<BarChartGroupData> barGroups = [];
            double maxY = 0.0;

            for (int i = 0; i < 30; i++) {
              final targetDate = now.subtract(Duration(days: 29 - i));
              final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
              final daySum = typeActivities
                  .where((a) => a.date.startsWith(dateStr))
                  .fold(0.0, (sum, a) => sum + a.value);
              if (daySum > maxY) maxY = daySum;
            }

            final chartMaxY = maxY > 0 ? maxY : 10.0;

            for (int i = 0; i < 30; i++) {
              final targetDate = now.subtract(Duration(days: 29 - i));
              final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

              final daySum = typeActivities
                  .where((a) => a.date.startsWith(dateStr))
                  .fold(0.0, (sum, a) => sum + a.value);

              barGroups.add(BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: daySum,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: 7,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: chartMaxY,
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ));
            }

            return MatteCard(
              margin: const EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.zero,
              color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0, top: 0, bottom: 0, width: 6,
                      child: Container(color: color),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${type[0].toUpperCase()}${type.substring(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(Icons.trending_up, color: color.withValues(alpha: 0.5), size: 18),
                            ],
                          ),
                          const SizedBox(height: 24),
                    SizedBox(
                      height: 140,
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
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
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
                              if (value % 6 != 0 && value != 29) {
                                return const Text('');
                              }
                              final daysAgo = 29 - value.toInt();
                              final date =
                                  now.subtract(Duration(days: daysAgo));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    daysAgo == 0
                                        ? 'Today'
                                        : DateFormat('MM/dd').format(date),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white60 : AppTheme.darkCharcoal)),
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
                              return Text(value.toInt().toString(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : AppTheme.darkCharcoal));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMaxY / 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
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

  Widget _buildBmiChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'BMI Trend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking your weight & height correlation',
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          MatteCard(
            height: 280,
            color: isDark ? const Color(0xFF0A2A3F) : AppTheme.skyBlue.withValues(alpha: 0.03),
            padding: const EdgeInsets.only(top: 24, right: 20, bottom: 10),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final log = _healthLogs[spot.x.toInt()];
                        return LineTooltipItem(
                          'BMI: ${log.bmi}\n${log.date}',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.darkCharcoal.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (_healthLogs.length / 5).clamp(1, 10).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _healthLogs.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _healthLogs[idx].date.substring(5),
                              style: TextStyle(
                                  fontSize: 10, color: isDark ? Colors.white60 : AppTheme.mutedGrey, fontWeight: FontWeight.w500),
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
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: TextStyle(
                                fontSize: 10, color: isDark ? Colors.white60 : AppTheme.mutedGrey, fontWeight: FontWeight.w500));
                      },
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
                    gradient: const LinearGradient(
                      colors: [AppTheme.skyBlue, AppTheme.emeraldGreen],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.skyBlue.withValues(alpha: 0.2),
                          AppTheme.skyBlue.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 18.5,
                      color: Colors.orange.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Underweight',
                        style: TextStyle(fontSize: 9, color: Colors.orange[300]),
                      ),
                    ),
                    HorizontalLine(
                      y: 25,
                      color: Colors.red.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Overweight',
                        style: TextStyle(fontSize: 9, color: Colors.red[300]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBmiCategory('< 18.5', 'Under', AppTheme.warmOrange),
              _buildBmiCategory('18.5-25', 'Normal', AppTheme.emeraldGreen),
              _buildBmiCategory('25-30', 'Over', AppTheme.warmOrange),
              _buildBmiCategory('> 30', 'Obese', Colors.redAccent),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(range,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedGrey)),
      ],
    );
  }
}
