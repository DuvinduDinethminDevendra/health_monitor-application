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
      case 'steps': return Icons.directions_walk_rounded;
      case 'workout': return Icons.fitness_center_rounded;
      case 'running': return Icons.directions_run_rounded;
      case 'cycling': return Icons.directions_bike_rounded;
      case 'swimming': return Icons.pool_rounded;
      case 'yoga': return Icons.self_improvement_rounded;
      case 'sleep': return Icons.bedtime_rounded;
      default: return Icons.star_rounded;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'steps': return AppTheme.scooter;
      case 'workout': return AppTheme.warmOrange;
      case 'running': return AppTheme.warmOrange;
      case 'cycling': return AppTheme.blueLagoon;
      case 'swimming': return AppTheme.skyBlue;
      case 'yoga': return AppTheme.scooter;
      case 'sleep': return AppTheme.sapphire;
      default: return AppTheme.blueLagoon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.blueLagoon));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Activities',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.sapphire,
                fontSize: 22,
                letterSpacing: -1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.sapphire),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: AppTheme.blueLagoon,
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
                      color: AppTheme.heather.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No activities logged yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.sapphire,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to log your first activity',
                    style: TextStyle(color: AppTheme.heather),
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
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MatteCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_getActivityIcon(activity.type), color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activity.value.toInt()} ${activity.unit}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppTheme.sapphire,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(DateTime.parse(activity.date)),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white38 : AppTheme.heather,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.5)),
                          onPressed: () async {
                            await _activityRepo.deleteActivity(activity.id!);
                            _loadActivities();
                          },
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
    final valueController = TextEditingController();
    final durationController = TextEditingController();
    final typeController = TextEditingController(text: 'Steps');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.sapphire : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: isDark ? Border.all(color: Colors.white12, width: 2) : null,
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Log Activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
            const SizedBox(height: 24),
            
            // Modern Activity Type Selector
            StatefulBuilder(
              builder: (context, setModalState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.heather, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Steps', 'Workout', 'Running', 'Cycling', 'Swimming', 'Yoga', 'Sleep'].map((type) => GestureDetector(
                        onTap: () => setModalState(() => typeController.text = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 85,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: typeController.text == type ? AppTheme.blueLagoon : (isDark ? Colors.white10 : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: typeController.text == type ? AppTheme.scooter : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getActivityIcon(type), color: typeController.text == type ? AppTheme.blueLagoon : (isDark ? Colors.white38 : Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: typeController.text == type ? AppTheme.blueLagoon : (isDark ? Colors.white38 : Colors.grey[600]))),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
              decoration: InputDecoration(
                labelText: 'Value (km / steps / units)',
                labelStyle: TextStyle(color: AppTheme.heather),
                prefixIcon: const Icon(Icons.add_chart_rounded, color: AppTheme.scooter),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.scooter)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
              decoration: InputDecoration(
                labelText: 'Duration (min)',
                labelStyle: TextStyle(color: AppTheme.heather),
                prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.scooter),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.scooter)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (valueController.text.isEmpty || durationController.text.isEmpty) return;
                final userId = Provider.of<AuthService>(context, listen: false).currentUser!.id!;
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
                backgroundColor: AppTheme.blueLagoon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Save Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
