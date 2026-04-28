import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../repositories/goal_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityRepository _activityRepo = ActivityRepository();
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final activities = await _activityRepo.getActivitiesByUser(userId);
    if (!mounted) return;
    setState(() {
      _activities = activities;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    String type = 'steps';
    final customTypeController = TextEditingController();
    final valueController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log Activity'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(value: 'steps', child: Text('Steps')),
                      DropdownMenuItem(
                          value: 'workout', child: Text('Workout')),
                      DropdownMenuItem(
                          value: 'running', child: Text('Running')),
                      DropdownMenuItem(
                          value: 'cycling', child: Text('Cycling')),
                      DropdownMenuItem(
                          value: 'swimming', child: Text('Swimming')),
                      DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                      DropdownMenuItem(value: 'sleep', child: Text('Sleep')),
                      DropdownMenuItem(
                          value: 'custom', child: Text('Custom Goal Metric')),
                    ],
                    onChanged: (val) => setDialogState(() => type = val!),
                    decoration: InputDecoration(
                      labelText: 'Activity Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (type == 'custom') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: customTypeController,
                      decoration: InputDecoration(
                        labelText: 'Custom Activity Name',
                        hintText: 'e.g. Reading, Meditation',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'sleep'
                          ? 'Hours Slept'
                          : type == 'steps'
                              ? 'Number of Steps'
                              : type == 'custom'
                                  ? 'Amount achieved'
                                  : 'Distance (km)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (type != 'sleep')
                    TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final userId =
                      Provider.of<AuthService>(context, listen: false)
                          .currentUser!
                          .id!;
                  final activity = Activity(
                    userId: userId,
                    type: type == 'custom'
                        ? customTypeController.text.trim().toLowerCase()
                        : type,
                    value: double.parse(valueController.text),
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    duration: type == 'sleep'
                        ? 0
                        : int.parse(durationController.text),
                  );
                  await _activityRepo.insertActivity(activity);

                  // Universal Sync: Push this activity natively to the matching Goals!
                  final goalRepo = GoalRepository();
                  final goals = await goalRepo.getGoalsByUser(userId);

                  for (var goal in goals) {
                    final typeMatch = goal.baseType;

                    if (typeMatch == activity.type.toLowerCase()) {
                      bool isDaily = goal.category.contains('(Daily)');
                      double newProgress;

                      if (isDaily) {
                        final dateStr =
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final activities = await _activityRepo
                            .getActivitiesByDateRange(userId, dateStr, dateStr);
                        final todaySum = activities
                            .where((a) => a.type.toLowerCase() == typeMatch)
                            .fold(0.0, (sum, a) => sum + a.value);
                        newProgress = todaySum;
                      } else {
                        newProgress = goal.currentValue + activity.value;
                      }

                      await goalRepo.updateProgress(goal.id!, newProgress);
                      if (newProgress >= goal.targetValue &&
                          !goal.isCompleted) {
                        await goalRepo.markCompleted(goal.id!);
                      }
                    }
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadActivities();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'steps':
        return Icons.directions_walk;
      case 'workout':
        return Icons.fitness_center;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.star;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'steps':
        return AppTheme.skyBlue;
      case 'workout':
        return AppTheme.warmOrange;
      case 'running':
        return AppTheme.warmOrange;
      case 'cycling':
        return AppTheme.emeraldGreen;
      case 'swimming':
        return AppTheme.skyBlue;
      case 'yoga':
        return AppTheme.emeraldGreen;
      case 'sleep':
        return AppTheme.darkCharcoal;
      default:
        return AppTheme.emeraldGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _activities.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run_rounded, size: 80, color: AppTheme.mutedGrey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'No activities logged yet',
                    style: TextStyle(fontSize: 18, color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to log your first activity',
                    style: TextStyle(color: AppTheme.mutedGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final color = _getActivityColor(activity.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getActivityIcon(activity.type), color: color),
                      ),
                      title: Text(
                        activity.type[0].toUpperCase() +
                            activity.type.substring(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${activity.type == 'steps' ? '${activity.value.toInt()} steps' : '${activity.value} km'} • ${activity.duration} min',
                        style: TextStyle(color: AppTheme.darkCharcoal.withValues(alpha: 0.6)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(activity.date,
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.mutedGrey)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20, color: AppTheme.warmOrange),
                            onPressed: () async {
                              await _activityRepo.deleteActivity(activity.id!);
                              _loadActivities();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
