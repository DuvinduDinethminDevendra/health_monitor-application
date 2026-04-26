import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notificationService = NotificationService();
  final List<_Reminder> _reminders = [
    _Reminder(
      id: 1,
      title: 'Morning Workout',
      body: 'Time for your daily exercise routine!',
      icon: Icons.fitness_center,
      color: Color(0xFFE53935),
      hour: 7,
      minute: 0,
      isEnabled: false,
    ),
    _Reminder(
      id: 2,
      title: 'Drink Water',
      body: 'Stay hydrated! Take a glass of water now.',
      icon: Icons.water_drop,
      color: Color(0xFF42A5F5),
      hour: 9,
      minute: 0,
      isEnabled: false,
    ),
    _Reminder(
      id: 3,
      title: 'Log Your Meals',
      body: 'Don\'t forget to log what you ate today.',
      icon: Icons.restaurant,
      color: Color(0xFFFB8C00),
      hour: 12,
      minute: 30,
      isEnabled: false,
    ),
    _Reminder(
      id: 4,
      title: 'Take a Walk',
      body: 'Get some fresh air! A 15-minute walk is great for your health.',
      icon: Icons.directions_walk,
      color: Color(0xFF00BFA5),
      hour: 15,
      minute: 0,
      isEnabled: false,
    ),
    _Reminder(
      id: 5,
      title: 'Log Your Weight',
      body: 'Time to track your weight and BMI progress.',
      icon: Icons.monitor_weight,
      color: Color(0xFFAB47BC),
      hour: 18,
      minute: 0,
      isEnabled: false,
    ),
    _Reminder(
      id: 6,
      title: 'Bedtime Reminder',
      body: 'Time to wind down. A good night\'s sleep is essential!',
      icon: Icons.bedtime,
      color: Color(0xFF5C6BC0),
      hour: 22,
      minute: 0,
      isEnabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reminders'),
        backgroundColor: const Color(0xFFAB47BC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active,
                    color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Stay On Track',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enable reminders to maintain healthy habits',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daily Reminders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._reminders.map((reminder) => _buildReminderCard(reminder)),
        ],
      ),
    );
  }

  Widget _buildReminderCard(_Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: reminder.color.withAlpha(30),
              child: Icon(reminder.icon, color: reminder.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(reminder.hour, reminder.minute),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.isEnabled,
              activeThumbColor: reminder.color,
              onChanged: (value) async {
                setState(() => reminder.isEnabled = value);
                if (value) {
                  await _notificationService.scheduleDaily(
                    id: reminder.id,
                    title: reminder.title,
                    body: reminder.body,
                    hour: reminder.hour,
                    minute: reminder.minute,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reminder.title} reminder enabled'),
                      backgroundColor: reminder.color,
                    ),
                  );
                } else {
                  await _notificationService.cancelNotification(reminder.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Reminder {
  final int id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final int hour;
  final int minute;
  bool isEnabled;

  _Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.hour,
    required this.minute,
    required this.isEnabled,
  });
}
