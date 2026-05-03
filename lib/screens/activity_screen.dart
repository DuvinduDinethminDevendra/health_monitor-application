// lib/screens/activity_screen.dart
//
// Activity Dashboard — Screen 1
// Member 3 responsibility: Data Layer + Activity Tracking
// Refactored in-place; preserves all existing imports and widget contracts.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../providers/activity_provider.dart';
import '../repositories/goal_repository.dart';
import '../services/auth_service.dart';
import '../theme/activity_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/activity/activity_error_state.dart';
import '../widgets/activity/activity_loading_skeleton.dart';
import '../widgets/activity/activity_stat_card.dart';
import '../widgets/activity/goal_progress_tile.dart';
import '../widgets/activity/quick_action_button.dart';
import '../widgets/activity/recent_activity_tile.dart';
import '../widgets/activity/section_header.dart';
import '../utils/ui_utils.dart';
import '../widgets/activity/smart_insight_card.dart';
import '../widgets/activity/step_progress_card.dart';
import '../widgets/activity/sync_status_badge.dart';
import '../widgets/activity/weekly_activity_chart.dart';
import '../l10n/app_localizations.dart';

import 'activity/activity_history_screen.dart';
import 'activity/workout_session_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Workout types offered in the pre-session picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kWorkoutTypes = [
  'Walking',
  'Running',
  'Cycling',
  'Gym',
  'Yoga',
  'Swimming',
  'Other',
];

// Icon map for the workout picker tiles
const Map<String, IconData> _kWorkoutIcons = {
  'Walking':  Icons.directions_walk,
  'Running':  Icons.directions_run,
  'Cycling':  Icons.directions_bike,
  'Gym':      Icons.fitness_center,
  'Yoga':     Icons.self_improvement,
  'Swimming': Icons.pool,
  'Other':    Icons.sports,
};

// ─────────────────────────────────────────────────────────────────────────────
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Tracks the last successful sync time for the header badge
  DateTime? _lastSyncTime;

  // Goal records loaded asynchronously alongside provider data
  List<Goal> _activityGoals = [];

  // Insight text from GoalRepository.getPredictiveInsight() for the first
  // step-type goal; falls back to ActivityProvider.smartInsightText
  String? _goalInsightText;

  final GoalRepository _goalRepo = GoalRepository();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Defer until first frame so context.read() is safe
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.id ?? '';

    // 1. Load provider data (steps, workouts, activities)
    await context.read<ActivityProvider>().loadData(userId);

    // 2. Load goals for the goal-progress section
    await _loadGoals(userId);

    // Mark sync time after both calls succeed
    if (mounted) {
      setState(() => _lastSyncTime = DateTime.now());
    }
  }

  Future<void> _loadGoals(String userId) async {
    try {
      final goals = await _goalRepo.getGoalsByUser(userId);
      // Keep only step/workout goals for this screen's goal section
      final relevant = goals.where((g) {
        final base = g.baseType;
        return base == 'steps' || base == 'walking' || base == 'running' ||
               base == 'workout' || base == 'cycling' || base == 'gym';
      }).toList();

      // Pull predictive insight from the first step goal, if any
      String? insight;
      final stepGoal = goals.where((g) => g.baseType == 'steps').firstOrNull;
      if (stepGoal?.id != null) {
        try {
          insight = await _goalRepo.getPredictiveInsight(stepGoal!.id!);
        } catch (_) {
          // Silently fall back — non-critical
        }
      }

      if (mounted) {
        setState(() {
          _activityGoals   = relevant;
          _goalInsightText = insight;
        });
      }
    } catch (_) {
      // Empty list fallback — section hides gracefully
    }
  }

  // ── Greeting helper ────────────────────────────────────────────────────────

  /// Returns "Good Morning", "Good Afternoon", or "Good Evening" based on
  /// the current hour so the header feels contextual.
  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final loc = AppLocalizations.of(context)!;
    if (hour < 12) return loc.greetingMorning;
    if (hour < 17) return loc.greetingAfternoon;
    return loc.greetingEvening;
  }

  // ── Workout type picker bottom sheet ──────────────────────────────────────

  /// Shows a modal bottom sheet where the user picks a workout type, then
  /// navigates to WorkoutSessionScreen with that type pre-selected.
  Future<void> _showWorkoutPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _WorkoutPickerSheet(),
    );

    if (selected == null || !mounted) return;

    if (!mounted) return;
    // New screen owns its own stopwatch; provider workout state not used here
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(workoutType: selected),
      ),
    );

    // Reload after returning so new workout appears in history
    if (mounted) await _loadAll();
  }

  // ── Log Activity bottom-sheet ──────────────────────────────────────────────

  Future<void> _openLogActivity() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogActivitySheet(
        isDark: isDark,
        onSaved: () async {
          if (mounted) await _loadAll();
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ActivityLoadingSkeleton(),
      );
    }

    if (provider.errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ActivityErrorState(
          message: provider.errorMessage!,
          onRetry: _loadAll,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: ActivityTheme.primaryBlue,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(provider),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: ActivityTheme.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildStepArc(provider),
                  const SizedBox(height: 16),
                  _buildQuickStatsRow(provider),
                  const SizedBox(height: 20),
                  _buildActionButtonsRow(),
                  const SizedBox(height: 24),
                  _buildSmartInsightCard(provider),
                  const SizedBox(height: 8),
                  _buildWeeklyChartSection(provider),
                  _buildGoalProgressSection(provider),
                  _buildRecentActivitySection(provider),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  /// Collapsible SliverAppBar that holds the greeting header + sync badge.
  Widget _buildSliverAppBar(ActivityProvider provider) {
    final user = context.read<AuthService>().currentUser;
    final name = (user != null && user.name.isNotEmpty)
        ? user.name.trim().split(' ').first
        : 'there';
    final loc = AppLocalizations.of(context)!;

    // Format the last sync time as "hh:mm AM/PM"
    final syncLabel = _lastSyncTime != null
        ? '${loc.syncedAt} ${DateFormat('hh:mm a').format(_lastSyncTime!)}'
        : loc.syncing;

    return SliverAppBar(
      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
      elevation: 0,
      floating: true,
      snap: true,
      expandedHeight: 100,
      collapsedHeight: kToolbarHeight,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: ActivityTheme.screenPadding,
            right: ActivityTheme.screenPadding,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_greeting(context)}, $name ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.sapphire),
                          ),
                        ),
                        Icon(
                          (DateTime.now().hour >= 6 && DateTime.now().hour < 18) ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, 
                          color: (DateTime.now().hour >= 6 && DateTime.now().hour < 18) ? AppTheme.warmOrange : AppTheme.skyBlue, 
                          size: 20
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SyncStatusBadge(
                      isSynced: provider.syncStatusText == 'Up to date',
                      lastSyncTime: syncLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Large semi-circle step arc — delegates entirely to existing StepProgressCard.
  Widget _buildStepArc(ActivityProvider provider) {
    return StepProgressCard(
      currentSteps: provider.liveStepCount,
      goalSteps: provider.dailyStepGoal,
    );
  }

  /// Three stat cards: Distance · Calories · Active Minutes
  Widget _buildQuickStatsRow(ActivityProvider provider) {
    final loc = AppLocalizations.of(context)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
          child: ActivityStatCard(
            title: loc.statDistance,
            // steps × 0.000762 km (average stride length)
            value: provider.todayDistanceKm.toStringAsFixed(2),
            unit: loc.unitKm,
            icon: Icons.map_outlined,
            iconColor: ActivityTheme.tealAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActivityStatCard(
            title: loc.statCalories,
            // steps × 0.04 kcal + workout calories
            value: provider.todayCalories.toString(),
            unit: loc.unitKcal,
            icon: Icons.local_fire_department_outlined,
            iconColor: ActivityTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActivityStatCard(
            title: loc.statActive,
            // (steps / 100) floor + total workout minutes
            value: provider.todayActiveMinutes.toString(),
            unit: loc.unitMin,
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFFAB47BC), // Purple
          ),
        ),
      ],
      ),
    );
  }

  /// Three action buttons: Start Workout · Log Activity · History
  Widget _buildActionButtonsRow() {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: 130, // Increased height to safely accommodate wrapped Sinhala text
      child: Row(
        children: [
          Expanded(
            child: QuickActionButton(
              label: loc.btnStartWorkout,
              icon: Icons.play_circle_outline,
              color: ActivityTheme.success,
              onTap: _showWorkoutPicker,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: QuickActionButton(
              label: loc.btnLogActivity,
              icon: Icons.add_circle_outline,
              color: ActivityTheme.primaryBlue,
              onTap: _openLogActivity,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: QuickActionButton(
              label: loc.btnHistory,
              icon: Icons.history,
              color: const Color(0xFFAB47BC),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Smart Insight card — prefers the GoalRepository predictive text (richer),
  /// falls back to ActivityProvider.smartInsightText (always available).
  Widget _buildSmartInsightCard(ActivityProvider provider) {
    final text = (_goalInsightText?.isNotEmpty == true)
        ? _goalInsightText!
        : provider.smartInsightText;

    return SmartInsightCard(message: text);
  }

  /// Weekly fl_chart bar chart with dashed goal line
  Widget _buildWeeklyChartSection(ActivityProvider provider) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.sectionWeeklyActivity,
          actionText: loc.btnDetails,
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
          ),
        ),
        WeeklyActivityChart(
          weeklySteps: provider.weeklySteps,
          dailyGoal: provider.dailyStepGoal,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Goal progress bars — Step Goal + Workout Goal pulled from GoalRepository
  Widget _buildGoalProgressSection(ActivityProvider provider) {
    final loc = AppLocalizations.of(context)!;
    // Always show at least the implicit step goal derived from provider
    final stepProgress = provider.stepProgress.clamp(0.0, 1.0);
    final stepPct      = '${(stepProgress * 100).toInt()}%';
    final stepRemaining = provider.remainingSteps;

    // Workout goal: count today's workouts vs. a reasonable daily target (1)
    final workoutDone   = provider.todaysWorkouts.length;

    // Find explicit workout goal if the user has set one
    Goal? workoutGoal;
    Goal? stepGoalModel;
    for (final g in _activityGoals) {
      if (g.baseType == 'steps' && stepGoalModel == null) stepGoalModel = g;
      if ((g.baseType == 'workout' || g.baseType == 'gym') && workoutGoal == null) {
        workoutGoal = g;
      }
    }

    final workoutTarget = workoutGoal?.targetValue.toInt() ?? 1;
    final workoutProg   = (workoutDone / workoutTarget).clamp(0.0, 1.0);
    final workoutPct    = '${(workoutProg * 100).toInt()}%';
    final workoutsLeft  = (workoutTarget - workoutDone).clamp(0, workoutTarget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: loc.sectionGoalProgress),
        GoalProgressTile(
          title: loc.titleStepGoal,
          progress: stepProgress,
          remainingText: stepRemaining > 0
              ? '$stepRemaining ${loc.stepsRemaining}'
              : loc.goalReached,
          percentageText: stepPct,
          icon: Icons.directions_walk,
          color: ActivityTheme.primaryBlue,
        ),
        GoalProgressTile(
          title: loc.titleWorkoutGoal,
          progress: workoutProg,
          remainingText: workoutsLeft > 0
              ? '$workoutsLeft ${loc.workoutsLeft}'
              : loc.workoutGoalComplete,
          percentageText: workoutPct,
          icon: Icons.fitness_center,
          color: ActivityTheme.success,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Last 3 recent activities with a "See All" link
  Widget _buildRecentActivitySection(ActivityProvider provider) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.sectionRecentActivity,
          actionText: loc.btnSeeAll,
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
          ),
        ),
        if (provider.recentActivities.isEmpty)
          const _EmptyActivityPlaceholder()
        else
          ...provider.recentActivities.take(3).map(
            (a) => RecentActivityTile(
              date: a.date,
              type: a.type,
              value: a.type == 'steps'
                  ? '${a.value.toInt()} steps'
                  : '${a.value.toStringAsFixed(1)} km',
              duration: a.duration.toString(),
              isSynced: true,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private: empty recent-activity placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyActivityPlaceholder extends StatelessWidget {
  const _EmptyActivityPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.emptyRecentActivity,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private: Workout type picker bottom sheet
// Returns the selected workout type string or null if dismissed.
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutPickerSheet extends StatelessWidget {
  const _WorkoutPickerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.chooseWorkoutType,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 16),
          // Grid of workout type chips
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            physics: const NeverScrollableScrollPhysics(),
            children: _kWorkoutTypes.map((type) {
              String localizedLabel = type;
              final loc = AppLocalizations.of(context)!;
              if (type == 'Walking') localizedLabel = loc.activityTypeWalking;
              if (type == 'Running') localizedLabel = loc.activityTypeRunning;
              if (type == 'Cycling') localizedLabel = loc.activityTypeCycling;
              if (type == 'Gym') localizedLabel = loc.activityTypeGym;
              if (type == 'Yoga') localizedLabel = loc.activityTypeYoga;
              if (type == 'Swimming') localizedLabel = loc.activityTypeSwimming;
              if (type == 'Other') localizedLabel = loc.activityTypeOther;

              return _WorkoutTypeTile(
                label: localizedLabel,
                icon: _kWorkoutIcons[type] ?? Icons.sports,
                onTap: () => Navigator.pop(context, type),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.btnCancel,
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private: single tile inside the workout picker grid
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutTypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _WorkoutTypeTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: ActivityTheme.primaryBlue.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ActivityTheme.primaryBlue.withAlpha(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ActivityTheme.primaryBlue, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ActivityTheme.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Activity Bottom Sheet — same premium style as Goal screen
// ─────────────────────────────────────────────────────────────────────────────
class _LogActivitySheet extends StatefulWidget {
  final bool isDark;
  final VoidCallback onSaved;

  const _LogActivitySheet({required this.isDark, required this.onSaved});

  @override
  State<_LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends State<_LogActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'steps';
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();
  final _customTypeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _types = ['steps', 'workout', 'running', 'cycling', 'swimming', 'yoga', 'custom'];

  @override
  void dispose() {
    _valueController.dispose();
    _durationController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId == null) { setState(() => _isLoading = false); return; }

    final finalType = _type == 'custom' ? _customTypeController.text.trim().toLowerCase() : _type;
    final value = double.parse(_valueController.text);
    final duration = _durationController.text.isEmpty ? 0 : int.parse(_durationController.text);

    await provider.logManualActivity(userId, finalType, value, duration, _selectedDate);

    if (mounted) {
      setState(() => _isLoading = false);
      if (provider.errorMessage != null) {
        UIUtils.showNotification(context, provider.errorMessage!, isError: true);
        provider.clearError();
      } else {
        widget.onSaved();
        Navigator.pop(context);
      }
    }
  }

  String _typeLabel(String t, AppLocalizations loc) {
    final labels = {
      'steps': loc.activityTypeWalking.replaceAll(RegExp(r'\s.*'), '') == 'Walking'
          ? 'Steps' : loc.lblNumSteps.split(' ').first,
      'workout': 'Workout',
      'running': loc.activityTypeRunning,
      'cycling': loc.activityTypeCycling,
      'swimming': loc.activityTypeSwimming,
      'yoga': loc.activityTypeYoga,
      'custom': loc.activityTypeCustom,
    };
    return labels[t] ?? t;
  }

  IconData _typeIcon(String t) {
    const icons = {
      'steps': Icons.directions_walk_rounded, 'workout': Icons.fitness_center_rounded,
      'running': Icons.directions_run_rounded, 'cycling': Icons.directions_bike_rounded,
      'swimming': Icons.pool_rounded, 'yoga': Icons.self_improvement_rounded,
      'custom': Icons.add_circle_outline_rounded,
    };
    return icons[t] ?? Icons.sports_rounded;
  }

  InputDecoration _fieldDecor(String label, IconData icon) {
    final isDark = widget.isDark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppTheme.heather, 
        fontSize: AppTheme.siSize(context, 14),
      ),
      prefixIcon: Icon(icon, color: AppTheme.scooter),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.scooter, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32 + MediaQuery.of(context).padding.bottom,
        left: 24, right: 24, top: 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.sapphire.withValues(alpha: 0.97) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 24),
              Text(loc.titleLogActivity,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppTheme.sapphire)),
              const SizedBox(height: 24),

              // Activity type selector
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? AppTheme.sapphire : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(loc.lblActivityType,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppTheme.sapphire)),
                          const SizedBox(height: 20),
                          ..._types.map((t) {
                            final isSelected = _type == t;
                            return ListTile(
                              onTap: () {
                                setState(() => _type = t);
                                Navigator.pop(ctx);
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.scooter : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_typeIcon(t),
                                  color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[600]),
                                  size: 20),
                              ),
                              title: Text(_typeLabel(t, loc),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? AppTheme.scooter : (isDark ? Colors.white70 : AppTheme.sapphire))),
                              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.scooter) : null,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                child: MatteCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Icon(_typeIcon(_type), color: AppTheme.scooter),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.lblActivityType, style: const TextStyle(fontSize: 12, color: AppTheme.heather)),
                            Text(_typeLabel(_type, loc), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.sapphire)),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.heather),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Custom type field
              if (_type == 'custom') ...[
                TextFormField(
                  controller: _customTypeController,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                  decoration: _fieldDecor('Custom Activity Name', Icons.edit_outlined),
                  validator: (v) => (v == null || v.isEmpty) ? loc.reqField : null,
                ),
                const SizedBox(height: 16),
              ],

              // Value + Duration row — equal flex so Duration is always visible
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: _fieldDecor(
                        _type == 'steps' 
                            ? loc.lblNumSteps.split(' ').first // "Number" -> "Steps" based on translation logic
                            : loc.statDistance,
                        Icons.speed_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return loc.reqField;
                        if (double.tryParse(v) == null) return loc.errValidNumber;
                        if (double.parse(v) < 0) return loc.errPositive;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: _fieldDecor(loc.unitMin.toUpperCase(), Icons.timer_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return loc.reqField;
                        if (int.tryParse(v) == null) return loc.errValidInt;
                        if (int.parse(v) < 0) return loc.errPositive;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date picker
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: isDark ? Colors.white : AppTheme.sapphire,
                  side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.scooter,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(loc.btnSaveActivity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
