// lib/screens/activity/workout_session_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_record.dart';
import '../../providers/activity_provider.dart';
import '../../repositories/goal_repository.dart';
import '../../repositories/workout_record_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/activity_theme.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../widgets/activity/activity_stat_card.dart';

// ── Icon map for header card ──────────────────────────────────────────────────
const Map<String, IconData> _kTypeIconsLarge = {
  'Walking':  Icons.directions_walk_rounded,
  'Running':  Icons.directions_run_rounded,
  'Cycling':  Icons.directions_bike_rounded,
  'Strength': Icons.fitness_center_rounded,
  'Gym':      Icons.fitness_center_rounded,
  'Yoga':     Icons.self_improvement_rounded,
  'Swimming': Icons.pool_rounded,
  'Other':    Icons.sports_rounded,
};

// ─────────────────────────────────────────────────────────────────────────────
class WorkoutSessionScreen extends StatefulWidget {
  final String workoutType;

  const WorkoutSessionScreen({super.key, required this.workoutType});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  // ── Session state ──────────────────────────────────────────────────────────
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _isPaused = false;
  bool _isSaving = false;

  // Snapshot of total steps when this session began (delta = session steps)
  int _sessionStartSteps = 0;

  // Predictive insight text loaded async from GoalRepository
  String _insightText = 'Loading insight…';

  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();
  final GoalRepository _goalRepo = GoalRepository();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Snapshot live step count so session delta starts at 0
      _sessionStartSteps = context.read<ActivityProvider>().liveStepCount;
      _startTimer();
      _loadInsight();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Timer helpers ──────────────────────────────────────────────────────────

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _pause() {
    _stopwatch.stop();
    setState(() => _isPaused = true);
  }

  void _resume() {
    _stopwatch.start();
    setState(() => _isPaused = false);
  }

  void _stopTimer() {
    _ticker?.cancel();
    _stopwatch.stop();
  }

  // ── Goal insight ───────────────────────────────────────────────────────────

  Future<void> _loadInsight() async {
    // Cache both before any await so we never cross an async gap with context
    final authService = context.read<AuthService>();
    final provider    = context.read<ActivityProvider>();
    try {
      final userId = authService.currentUser?.id ?? '';
      final goals  = await _goalRepo.getGoalsByUser(userId);
      final step   = goals.where((g) => g.baseType == 'steps').firstOrNull;
      if (step?.id != null) {
        final text = await _goalRepo.getPredictiveInsight(step!.id!);
        if (mounted) setState(() => _insightText = text);
      } else {
        final rem = provider.remainingSteps;
        if (mounted) {
          setState(() => _insightText = rem > 0
              ? 'You need $rem more steps to reach today\'s goal.'
              : 'Daily step goal reached! Great work! 🎉');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _insightText = 'Keep moving – every step counts!');
    }
  }

  // ── Session computations ───────────────────────────────────────────────────

  int _sessionSteps(ActivityProvider p) =>
      max(0, p.liveStepCount - _sessionStartSteps);

  double _distanceKm(int steps) => steps * 0.000762;

  int _calories(int steps) => (steps * 0.04).toInt();

  /// Pace in min/km → formatted as "MM'SS\""
  String _paceString(int steps) {
    final dist = _distanceKm(steps);
    if (dist <= 0) return '–';
    final elapsedMin = _stopwatch.elapsed.inSeconds / 60.0;
    final paceMin    = elapsedMin / dist; // min per km
    final mm = paceMin.floor();
    final ss = ((paceMin - mm) * 60).round();
    return "${mm.toString().padLeft(2, '0')}'${ss.toString().padLeft(2, '0')}\"";
  }

  /// Cadence in steps/min
  int _cadence(int steps) {
    final elapsedMin = _stopwatch.elapsed.inSeconds / 60.0;
    if (elapsedMin < 1) return 0;
    return (steps / elapsedMin).round();
  }

  String _formatHMS(Duration d) {
    final h  = d.inHours.toString().padLeft(2, '0');
    final m  = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s  = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Finish & save ──────────────────────────────────────────────────────────

  Future<void> _handleFinish() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Workout?'),
        content: const Text('Stop the session and save your workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ActivityTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    _stopTimer();

    try {
      final authService = context.read<AuthService>();
      final provider    = context.read<ActivityProvider>();
      final userId      = authService.currentUser?.id ?? '';

      final steps    = _sessionSteps(provider);
      final dist     = _distanceKm(steps);
      final cals     = _calories(steps);
      final durationMins = max(1, (_stopwatch.elapsed.inSeconds / 60).ceil());
      final loggedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Persist to workout_records table
      final record = WorkoutRecord(
        userId:        userId,
        workoutType:   widget.workoutType,
        durationMins:  durationMins,
        caloriesBurned: cals,
        loggedAt:      loggedAt,
        notes: 'steps:$steps dist:${dist.toStringAsFixed(2)}km',
      );
      await _workoutRepo.insertWorkout(record);

      // Mirror into activities + trigger goal sync
      await provider.logManualActivity(
        userId,
        widget.workoutType.toLowerCase(),
        dist,
        durationMins,
        DateTime.now(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      UIUtils.showNotification(
        context,
        'Workout saved successfully!',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      UIUtils.showNotification(
        context,
        'Failed to save: $e',
        isError: true,
      );
    }
  }

  Future<void> _handleStop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('Stop without saving? Progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
            TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.roseRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _stopTimer();
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ActivityProvider>();
    final steps     = _sessionSteps(provider);
    final elapsed   = _stopwatch.elapsed;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ActivityTheme.screenPadding,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeHeaderCard(),
              const SizedBox(height: 16),
              _buildLiveTimer(elapsed),
              const SizedBox(height: 16),
              _buildLiveStepArc(steps, provider.dailyStepGoal),
              const SizedBox(height: 16),
              _buildQuickStatsRow(steps),
              const SizedBox(height: 16),
              _buildStatsGrid(steps, elapsed),
              const SizedBox(height: 16),
              _buildRoutePlaceholder(),
              const SizedBox(height: 20),
              _buildControlButtons(),
              SizedBox(height: 16),
              _buildInsightStrip(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.sapphire),
      title: Text(
        'Workout Session',
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.sapphire,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTypeHeaderCard() {
    final icon = _kTypeIconsLarge[widget.workoutType] ?? Icons.sports_rounded;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.scooter,
            AppTheme.scooter.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.scooter.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workoutType,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isPaused ? AppTheme.warmOrange : AppTheme.emeraldGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaused ? 'Session Paused' : 'Live Tracking',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTimer(Duration elapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MatteCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            _formatHMS(elapsed),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.sapphire,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DURATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.scooter,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStepArc(int steps, int dailyGoal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = dailyGoal > 0 ? (steps / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return MatteCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 160,
                width: 200,
                child: CustomPaint(
                  painter: _SessionArcPainter(
                    progress: progress,
                    trackColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    arcColor: AppTheme.scooter,
                    strokeWidth: 16,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    steps.toString(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.sapphire,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'SESSION STEPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.heather,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.emeraldGreen),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(int steps) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ActivityStatCard(
              title: 'Distance',
              value: _distanceKm(steps).toStringAsFixed(2),
              unit: 'km',
              icon: Icons.map_outlined,
              iconColor: AppTheme.emeraldGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ActivityStatCard(
              title: 'Calories',
              value: _calories(steps).toString(),
              unit: 'kcal',
              icon: Icons.local_fire_department_outlined,
              iconColor: AppTheme.warmOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ActivityStatCard(
              title: 'Pace',
              value: _paceString(steps),
              unit: 'min/km',
              icon: Icons.speed_outlined,
              iconColor: AppTheme.scooter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int steps, Duration elapsed) {
    final cadence = _cadence(steps);
    final pace    = _paceString(steps);
    final mm      = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss      = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.0,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGridCell('Duration',    '$mm:$ss',       Icons.timer_outlined,      ActivityTheme.primaryBlue),
        _buildGridCell('Avg Pace',    pace,             Icons.trending_up,         ActivityTheme.tealAccent),
        _buildGridCell('Cadence',     '$cadence spm',  Icons.directions_walk,     ActivityTheme.warning),
        _buildGridCell('Heart Rate',  '– bpm',         Icons.favorite_border,     ActivityTheme.error),
      ],
    );
  }

  Widget _buildGridCell(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MatteCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.heather,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.sapphire,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MatteCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(Icons.map_outlined, color: AppTheme.heather, size: 22),
          const SizedBox(width: 12),
          Text(
            'Route tracking not enabled',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.heather,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        // Pause / Resume
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(_isPaused ? 'Resume' : 'Pause'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.scooter,
              side: const BorderSide(color: AppTheme.scooter, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: _isPaused ? _resume : _pause,
          ),
        ),
        const SizedBox(width: 12),
        // Stop (discard)
        Container(
          decoration: BoxDecoration(
            color: AppTheme.roseRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.roseRed.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.stop_rounded, color: AppTheme.roseRed),
            tooltip: 'Discard',
            onPressed: _handleStop,
            padding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(width: 12),
        // Finish & Save
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(_isSaving ? 'Saving…' : 'Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.scooter,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            onPressed: _isSaving ? null : _handleFinish,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightStrip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MatteCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.scooter, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _insightText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.sapphire,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local semi-arc painter — same geometry as StepProgressCard's painter,
// kept private so step_progress_card.dart remains untouched.
// ─────────────────────────────────────────────────────────────────────────────
class _SessionArcPainter extends CustomPainter {
  final double progress;   // 0.0–1.0
  final Color  trackColor;
  final Color  arcColor;
  final double strokeWidth;

  const _SessionArcPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width / 2, size.height) - strokeWidth / 2;

    final trackPaint = Paint()
      ..color       = trackColor
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final arcPaint = Paint()
      ..color       = arcColor
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height), radius: radius),
      pi, pi, false, trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height), radius: radius),
        pi, pi * progress, false, arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SessionArcPainter old) =>
      old.progress != progress;
}
