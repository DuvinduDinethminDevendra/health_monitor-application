// lib/screens/activity/activity_history_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/step_record.dart';
import '../../models/workout_record.dart';

import '../../repositories/step_record_repository.dart';
import '../../repositories/workout_record_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/activity_theme.dart';
import '../../theme/app_theme.dart';

// ── Color map for workout type circles ────────────────────────────────────────
const Map<String, Color> _kTypeColors = {
  'Walking':  Color(0xFF14B8A6), // teal
  'Running':  Color(0xFFF97316), // orange
  'Yoga':     Color(0xFFAB47BC), // purple
  'Cycling':  Color(0xFF2563EB), // blue
  'Strength': Color(0xFFEF4444), // red
  'Gym':      Color(0xFFEF4444), // red
  'Swimming': Color(0xFF06B6D4), // cyan
  'Other':    Color(0xFF64748B), // grey
};

const Map<String, IconData> _kTypeIcons = {
  'Walking':  Icons.directions_walk,
  'Running':  Icons.directions_run,
  'Yoga':     Icons.self_improvement,
  'Cycling':  Icons.directions_bike,
  'Strength': Icons.fitness_center,
  'Gym':      Icons.fitness_center,
  'Swimming': Icons.pool,
  'Other':    Icons.sports,
};

enum _Period { day, week, month }

// ─────────────────────────────────────────────────────────────────────────────
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  _Period _selectedPeriod = _Period.week;

  // Loaded data
  List<StepRecord>   _weeklySteps = [];
  List<WorkoutRecord> _recentWorkouts = [];
  bool _isLoading = true;

  final StepRecordRepository   _stepRepo    = StepRecordRepository();
  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();

  // All workouts in the last 7 days — used for per-day active minutes
  List<WorkoutRecord> _weeklyWorkouts = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthService>().currentUser?.id ?? '';
    try {
      final steps    = await _stepRepo.getLast7DaysSteps(userId);
      final workouts = await _workoutRepo.getWorkoutsByUser(userId);

      // Cutoff for "this week" (last 7 days)
      final cutoff = DateTime.now().subtract(const Duration(days: 6));
      final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoff);

      if (mounted) {
        setState(() {
          _weeklySteps    = steps;
          // All workouts from the last 7 days — for daily log active minutes
          _weeklyWorkouts = workouts
              .where((w) => w.loggedAt.compareTo(cutoffStr) >= 0)
              .toList();
          // Top-5 most recent — for the Recent Workouts display section
          _recentWorkouts = workouts.take(5).toList();
          _isLoading      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Derived summary values ─────────────────────────────────────────────────

  int get _totalSteps     => _weeklySteps.fold(0, (s, r) => s + r.stepCount);
  int get _totalCalories  => (_totalSteps * 0.04).toInt();
  // Active minutes: sum workout durations for the last 7 days
  int get _totalActiveMin {
    final cutoff = DateTime.now().subtract(const Duration(days: 6));
    return _weeklyWorkouts
        .where((w) {
          try {
            final d = DateTime.parse(w.loggedAt);
            return d.isAfter(cutoff);
          } catch (_) {
            return false;
          }
        })
        .fold(0, (s, w) => s + w.durationMins);
  }


  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ActivityTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: ActivityTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ActivityTheme.screenPadding,
                  vertical: 8,
                ),
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryRow(),
                  const SizedBox(height: 20),
                  _buildChartSection(),
                  const SizedBox(height: 20),
                  _buildDailyLogSection(),
                  SizedBox(height: 20),
                  _buildRecentWorkoutsSection(),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
      elevation: 0,
      iconTheme: IconThemeData(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
      title: Text(
        'Activity History',
        style: TextStyle(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
          tooltip: 'Filter',
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: _Period.values.map((p) {
          final isSelected = p == _selectedPeriod;
          final label = p.name[0].toUpperCase() + p.name.substring(1);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.scooter : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary row ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(child: _buildSummaryTile('Total Steps', NumberFormat.decimalPattern().format(_totalSteps), Icons.directions_walk, AppTheme.skyBlue)),
        SizedBox(width: 10),
        Expanded(child: _buildSummaryTile('Active Min', '$_totalActiveMin', Icons.timer_outlined, AppTheme.emeraldGreen)),
        SizedBox(width: 10),
        Expanded(child: _buildSummaryTile('Calories', '$_totalCalories', Icons.local_fire_department_outlined, AppTheme.warmOrange)),
      ],
    );
  }

  Widget _buildSummaryTile(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MatteCard(
      height: 100,
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      color: isDark ? color.withValues(alpha: 0.85) : color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────

  Widget _buildChartSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Steps', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
        SizedBox(height: 12),
        MatteCard(
          height: 260,
          padding: const EdgeInsets.only(top: 20, right: 12, left: 0, bottom: 12),
          color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
          child: _buildBarChart(),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_weeklySteps.isEmpty) {
      return Center(child: Text('No data', style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)))));
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final goal  = dailyGoal.toDouble();
    double maxY = goal;
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < _weeklySteps.length; i++) {
      final rec   = _weeklySteps[i];
      final steps = rec.stepCount.toDouble();
      if (steps > maxY) maxY = steps;
      final isToday = rec.date == today;

      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: steps,
            color: isToday ? ActivityTheme.primaryBlue : ActivityTheme.primaryBlue.withAlpha(80),
            width: 18,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.1,
              color: Colors.grey.withAlpha(18),
            ),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= _weeklySteps.length) return const SizedBox.shrink();
                try {
                  final d = DateTime.parse(_weeklySteps[idx].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('E').format(d).substring(0, 1),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)))),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Text(NumberFormat.compact().format(val),
                    style: TextStyle(fontSize: 10, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B))), textAlign: TextAlign.center);
              },
            ),
          ),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: goal > 0 ? goal : 10000,
          getDrawingHorizontalLine: (val) => FlLine(
            color: val == goal ? ActivityTheme.warning.withAlpha(150) : Colors.grey.withAlpha(40),
            strokeWidth: val == goal ? 2 : 1,
            dashArray: val == goal ? [4, 4] : null,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  int get dailyGoal => _weeklySteps.isNotEmpty
      ? _weeklySteps.first.goal
      : 10000;

  // ── Daily log list ─────────────────────────────────────────────────────────

  Widget _buildDailyLogSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Log', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
        SizedBox(height: 8),
        MatteCard(
          padding: EdgeInsets.zero,
          color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
          child: Column(
            children: List.generate(_weeklySteps.length, (i) {
              final rec      = _weeklySteps[i];
              final goalMet  = rec.stepCount >= rec.goal;
              final calories = (rec.stepCount * 0.04).toInt();
              // Active minutes for this day — from the full week workout list
              final activeMins = _weeklyWorkouts
                  .where((w) => w.loggedAt.startsWith(rec.date))
                  .fold(0, (s, w) => s + w.durationMins);

              DateTime? date;
              try { date = DateTime.parse(rec.date); } catch (_) {}

              return Column(
                children: [
                  _DailyLogRow(
                    dayLabel:   date != null ? DateFormat('EEE').format(date) : '--',
                    dateLabel:  date != null ? DateFormat('MMM d').format(date) : rec.date,
                    steps:      rec.stepCount,
                    goalSteps:  rec.goal,
                    goalMet:    goalMet,
                    activeMin:  activeMins,
                    calories:   calories,
                  ),
                  if (i < _weeklySteps.length - 1)
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withAlpha(30)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Recent workouts ────────────────────────────────────────────────────────

  Widget _buildRecentWorkoutsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Workouts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
            TextButton(
              onPressed: () {},   // View All — no action required
              child: Text('View All', style: TextStyle(color: AppTheme.blueLagoon, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 4),
        if (_recentWorkouts.isEmpty)
          MatteCard(
            padding: const EdgeInsets.all(24),
            color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
            child: Center(
              child: Text('No workouts recorded yet.', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.heather, fontWeight: FontWeight.w700)),
            ),
          )
        else
          MatteCard(
            padding: EdgeInsets.zero,
            color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
            child: Column(
              children: List.generate(_recentWorkouts.length, (i) {
                final w = _recentWorkouts[i];
                return Column(
                  children: [
                    _WorkoutRow(workout: w),
                    if (i < _recentWorkouts.length - 1)
                      Divider(height: 1, indent: 64, endIndent: 16, color: Colors.grey.withAlpha(30)),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  // ── Filter bottom sheet ────────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        selected: _selectedPeriod,
        onSelected: (p) {
          setState(() => _selectedPeriod = p);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily log row widget
// ─────────────────────────────────────────────────────────────────────────────
class _DailyLogRow extends StatelessWidget {
  final String dayLabel;
  final String dateLabel;
  final int    steps;
  final int    goalSteps;
  final bool   goalMet;
  final int    activeMin;
  final int    calories;

  const _DailyLogRow({
    required this.dayLabel,
    required this.dateLabel,
    required this.steps,
    required this.goalSteps,
    required this.goalMet,
    required this.activeMin,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Day + date
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : AppTheme.sapphire)),
                Text(dateLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
              ],
            ),
          ),
          SizedBox(width: 12),

          // Steps (blue if goal met)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormat.decimalPattern().format(steps),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: goalMet ? ActivityTheme.primaryBlue : (isDark ? Colors.white : AppTheme.sapphire),
                  ),
                ),
                Text('steps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
              ],
            ),
          ),

          // Active min
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$activeMin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                Text('min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
              ],
            ),
          ),

          // Calories
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$calories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                Text('kcal', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
              ],
            ),
          ),

          // Goal indicator
          Icon(
            goalMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: goalMet ? ActivityTheme.success : Colors.grey.withAlpha(120),
            size: 20,
          ),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)), size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent workout row widget
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutRow extends StatelessWidget {
  final WorkoutRecord workout;

  const _WorkoutRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type     = workout.workoutType;
    final color    = _kTypeColors[type] ?? _kTypeColors['Other']!;
    final icon     = _kTypeIcons[type]  ?? Icons.sports;
    final cals     = workout.caloriesBurned ?? 0;

    String dateLabel = '';
    try {
      final d = DateTime.parse(workout.loggedAt);
      dateLabel = DateFormat('MMM d · h:mm a').format(d);
    } catch (_) {
      dateLabel = workout.loggedAt;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Colored circle icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 12),

          // Workout name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                SizedBox(height: 2),
                Text(dateLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
              ],
            ),
          ),

          // Duration + calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${workout.durationMins} min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
              Text('$cals kcal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppTheme.heather)),
            ],
          ),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)), size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onSelected;

  const _FilterSheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(height: 16),
          Text('Filter Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)))),
          SizedBox(height: 16),
          ...[ _Period.day, _Period.week, _Period.month ].map((p) {
            final label = p.name[0].toUpperCase() + p.name.substring(1);
            final isSelected = p == selected;
            return ListTile(
              title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)))),
              trailing: isSelected ? const Icon(Icons.check, color: ActivityTheme.primaryBlue) : null,
              onTap: () => onSelected(p),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }),
        ],
      ),
    );
  }
}
