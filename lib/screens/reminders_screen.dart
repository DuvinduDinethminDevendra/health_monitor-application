import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';
import 'edit_reminder_screen.dart';

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
    const colors = [
      Color(0xFFE53935),
      Color(0xFF42A5F5),
      Color(0xFFFB8C00),
      Color(0xFF00BFA5),
      Color(0xFFAB47BC),
      Color(0xFF5C6BC0),
    ];
    if (id >= 1 && id <= 6) return colors[id - 1];
    return colors[id % colors.length];
  }

  void _navigateToEdit(BuildContext context, {Reminder? reminder}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(reminder: reminder),
      ),
    );
  }

  Future<void> _confirmDeleteSelected(BuildContext context, RemindersProvider provider) async {
    final count = provider.selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reminders'),
        content: Text('Are you sure you want to delete $count reminder${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await provider.deleteSelected();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deleted reminder${deleted > 1 ? 's' : ''} deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, provider, _) {
        final isSelecting = provider.isSelecting;

        return Scaffold(
          appBar: AppBar(
            title: isSelecting
                ? Text('${provider.selectedIds.length} selected')
                : const Text('Health Reminders'),
            backgroundColor: isSelecting ? Colors.grey[700] : const Color(0xFFAB47BC),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: provider.clearSelection,
                  )
                : null,
            actions: isSelecting
                ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: 'Select All',
                      onPressed: provider.selectAll,
                    ),
                  ]
                : null,
          ),
          floatingActionButton: isSelecting
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _navigateToEdit(context),
                  backgroundColor: const Color(0xFFAB47BC),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('New Reminder'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
          bottomNavigationBar: isSelecting
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDeleteSelected(context, provider),
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Delete (${provider.selectedIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: isSelecting ? 16 : 100,
                  ),
                  children: [
                    if (!isSelecting) ...[
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
                            Icon(Icons.notifications_active, color: Colors.white, size: 32),
                            SizedBox(height: 12),
                            Text(
                              'Stay On Track',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                    ],
                    ...provider.reminders.map(
                      (reminder) => _buildReminderCard(context, provider, reminder),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, RemindersProvider provider, Reminder reminder) {
    final color = _getColorForId(reminder.id);
    final icon = _getIconForId(reminder.id);
    final isCustom = reminder.id > 6;
    final isSelected = provider.selectedIds.contains(reminder.id);
    final isSelecting = provider.isSelecting;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Reminder'),
            content: Text('Are you sure you want to delete \'${reminder.title}\'?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await provider.deleteReminder(reminder);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${reminder.title}" deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Colors.redAccent, width: 2)
              : BorderSide.none,
        ),
        color: isSelected ? Colors.red.withAlpha(15) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSelecting
              ? () => provider.toggleSelection(reminder.id)
              : () => _navigateToEdit(context, reminder: reminder),
          onLongPress: () => provider.toggleSelection(reminder.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.redAccent : Colors.grey,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withAlpha(30),
                    child: Icon(icon, color: color, size: 22),
                  ),
                if (!isSelecting) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          if (isCustom && !isSelecting)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Custom',
                                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(reminder.hour, reminder.minute),
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            reminder.alertStyle == AlertStyle.alarm
                                ? Icons.alarm
                                : Icons.notifications_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            reminder.alertStyle == AlertStyle.alarm ? 'Alarm' : 'Banner',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isSelecting)
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
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
