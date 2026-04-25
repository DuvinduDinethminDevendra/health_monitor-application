import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  IconData _getIconForId(int id) {
    switch (id) {
      case 1: return Icons.fitness_center;
      case 2: return Icons.water_drop;
      case 3: return Icons.restaurant;
      case 4: return Icons.directions_walk;
      case 5: return Icons.monitor_weight;
      case 6: return Icons.bedtime;
      default: return Icons.notifications;
    }
  }

  Color _getColorForId(int id) {
    switch (id) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFF42A5F5);
      case 3: return const Color(0xFFFB8C00);
      case 4: return const Color(0xFF00BFA5);
      case 5: return const Color(0xFFAB47BC);
      case 6: return const Color(0xFF5C6BC0);
      default: return const Color(0xFFAB47BC);
    }
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
      body: Consumer<RemindersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
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
              ...provider.reminders.map((reminder) => _buildReminderCard(context, provider, reminder)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, RemindersProvider provider, Reminder reminder) {
    final color = _getColorForId(reminder.id);
    final icon = _getIconForId(reminder.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color, size: 22),
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
              activeColor: color,
              onChanged: (value) async {
                await provider.toggleReminder(reminder, value);
                if (value && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reminder.title} reminder enabled'),
                      backgroundColor: color,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
