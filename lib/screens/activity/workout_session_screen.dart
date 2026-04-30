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
import '../../widgets/activity/activity_stat_card.dart';

// ── Icon map for header card ──────────────────────────────────────────────────
const Map<String, String> _kTypeEmoji = {
  'Walking':  '🚶',
  'Running':  '🏃',
  'Cycling':  '🚴',
  'Strength': '💪',
  'Gym':      '💪',
  'Yoga':     '🧘',
  'Swimming': '🏊',
  'Other':    '🏅',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved!'),
          backgroundColor: ActivityTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: ActivityTheme.error,
        ),
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
            style: TextButton.styleFrom(foregroundColor: ActivityTheme.error),
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
    return AppBar(
      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
      elevation: 0,
      iconTheme: IconThemeData(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
      title: Text(
        'Workout Session',
        style: TextStyle(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeHeaderCard() {
    final emoji = _kTypeEmoji[widget.workoutType] ?? '🏅';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: ActivityTheme.primaryBlue,
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workoutType,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _isPaused ? 'Paused' : 'In Progress',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Animated live indicator dot
          if (!_isPaused)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveTimer(Duration elapsed) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatHMS(elapsed),
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Duration',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ActivityTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStepArc(int steps, int dailyGoal) {
    // Progress relative to the full day goal so the arc is meaningful
    final progress = dailyGoal > 0
        ? (steps / dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              // Arc painter (same math as _SemiCircleProgressPainter)
              SizedBox(
                height: 150,
                width: 190,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(190, 150),
                      painter: _SessionArcPainter(
                        progress: progress,
                        trackColor: Colors.grey.withAlpha(30),
                        arcColor: ActivityTheme.primaryBlue,
                        strokeWidth: 15,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          steps.toString(),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'session steps',
                          style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B))),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ),
              ),
              // "● Live" pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ActivityTheme.primaryBlue.withAlpha(22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ActivityTheme.primaryBlue.withAlpha(60)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: ActivityTheme.primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ActivityTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(int steps) {
    return Row(
      children: [
        Expanded(
          child: ActivityStatCard(
            title: 'Distance',
            value: _distanceKm(steps).toStringAsFixed(2),
            unit: 'km',
            icon: Icons.map_outlined,
            iconColor: ActivityTheme.tealAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ActivityStatCard(
            title: 'Calories',
            value: _calories(steps).toString(),
            unit: 'kcal',
            icon: Icons.local_fire_department_outlined,
            iconColor: ActivityTheme.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ActivityStatCard(
            title: 'Pace',
            value: _paceString(steps),
            unit: 'min/km',
            icon: Icons.speed_outlined,
            iconColor: ActivityTheme.primaryBlue,
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)))),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(ActivityTheme.cardRadius),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.map_outlined, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)), size: 22),
          SizedBox(width: 12),
          Text(
            'Route tracking not enabled',
            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)), fontSize: 14),
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
          child: OutlinedButton.icon(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(_isPaused ? 'Resume' : 'Pause'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ActivityTheme.primaryBlue,
              side: const BorderSide(color: ActivityTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isPaused ? _resume : _pause,
          ),
        ),
        const SizedBox(width: 10),
        // Stop (discard)
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ActivityTheme.error,
              side: const BorderSide(color: ActivityTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleStop,
          ),
        ),
        const SizedBox(width: 10),
        // Finish & Save
        Expanded(
          child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Saving…' : 'Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ActivityTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSaving ? null : _handleFinish,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ActivityTheme.primaryBlue.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ActivityTheme.primaryBlue.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: ActivityTheme.primaryBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _insightText,
              style: TextStyle(
                fontSize: 13,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
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
    final center = Offset(size.width / 2, size.height);
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
      Rect.fromCircle(center: center, radius: radius),
      pi, pi, false, trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi, pi * progress, false, arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SessionArcPainter old) =>
      old.progress != progress;
}
