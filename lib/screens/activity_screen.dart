import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../services/auth_service.dart';

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
                    ],
                    onChanged: (val) => setDialogState(() => type = val!),
                    decoration: InputDecoration(
                      labelText: 'Activity Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          type == 'steps' ? 'Number of Steps' : 'Distance (km)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                      if (int.tryParse(v) == null)
                        return 'Enter a valid number';
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
                    type: type,
                    value: double.parse(valueController.text),
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    duration: int.parse(durationController.text),
                  );
                  await _activityRepo.insertActivity(activity);
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
    switch (type) {
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
      default:
        return Icons.directions_run;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'steps':
        return const Color(0xFF1A73E8);
      case 'workout':
        return const Color(0xFFE53935);
      case 'running':
        return const Color(0xFFFB8C00);
      case 'cycling':
        return const Color(0xFF00BFA5);
      case 'swimming':
        return const Color(0xFF42A5F5);
      case 'yoga':
        return const Color(0xFFAB47BC);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No activities logged yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to log your first activity',
                    style: TextStyle(color: Colors.grey[400]),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(30),
                      child:
                          Icon(_getActivityIcon(activity.type), color: color),
                    ),
                    title: Text(
                      activity.type[0].toUpperCase() +
                          activity.type.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${activity.type == 'steps' ? '${activity.value.toInt()} steps' : '${activity.value} km'} • ${activity.duration} min',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(activity.date,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
