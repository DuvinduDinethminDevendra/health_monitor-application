import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
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
      appBar: AppBar(
        title: const Text('My Activities',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.darkCharcoal,
                fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: AppTheme.emeraldGreen,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run_rounded,
                      size: 80,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'No activities logged yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.darkCharcoal,
                        fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final color = _getActivityColor(activity.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 6,
                          child: Container(color: color),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(_getActivityIcon(activity.type),
                                    color: color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.type.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                          letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.type.toLowerCase() == 'steps'
                                          ? '${activity.value.toInt()} steps'
                                          : '${activity.value} km',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkCharcoal),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    activity.date,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedGrey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activity.duration} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkCharcoal
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.5),
                                    size: 20),
                                onPressed: () async {
                                  await _activityRepo
                                      .deleteActivity(activity.id!);
                                  _loadActivities();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDialog() {
    final typeController = TextEditingController(text: 'Running');
    final valueController = TextEditingController();
    final durationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Log New Activity',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkCharcoal)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: 'Running',
              items: [
                'Running',
                'Cycling',
                'Swimming',
                'Workout',
                'Yoga',
                'Steps',
                'Sleep'
              ]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => typeController.text = val!,
              decoration: InputDecoration(
                labelText: 'Activity Type',
                prefixIcon: const Icon(Icons.category_rounded,
                    color: AppTheme.emeraldGreen),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Value (km / steps)',
                prefixIcon: const Icon(Icons.add_chart_rounded,
                    color: AppTheme.emeraldGreen),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (min)',
                prefixIcon: const Icon(Icons.timer_rounded,
                    color: AppTheme.emeraldGreen),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (valueController.text.isEmpty ||
                    durationController.text.isEmpty) return;
                final userId = Provider.of<AuthService>(context, listen: false)
                    .currentUser!
                    .id!;
                final activity = Activity(
                  userId: userId,
                  type: typeController.text,
                  value: double.parse(valueController.text),
                  date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  duration: int.parse(durationController.text),
                );
                await _activityRepo.insertActivity(activity);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadActivities();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Save Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
