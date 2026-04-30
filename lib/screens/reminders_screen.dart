import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
import '../models/reminder.dart';
import 'edit_reminder_screen.dart';
import 'package:health_monitor/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text('${AppLocalizations.of(context)!.confirmDeleteMsg} $count?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context)!.delete),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Scaffold(
          backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
          appBar: AppBar(
            title: isSelecting
                ? Text('${provider.selectedIds.length} ${AppLocalizations.of(context)!.selected}')
                : Text(AppLocalizations.of(context)!.healthReminders),
            backgroundColor: isSelecting ? Colors.grey[700] : primaryColor,
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
                  heroTag: 'reminders_fab',
                  onPressed: () => _navigateToEdit(context),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_alarm),
                  label: Text(AppLocalizations.of(context)!.newReminder),
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
                        label: Text('${AppLocalizations.of(context)!.delete} (${provider.selectedIds.length})'),
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
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.stayOnTrack,
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black87),
                            ),
                            SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.enableRemindersDesc,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ...provider.reminders.map(
                      (reminder) => _buildReminderCard(context, provider, reminder, isDark, primaryColor),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, RemindersProvider provider, Reminder reminder, bool isDark, Color primaryColor) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)!.deleteReminder),
            content: Text('${AppLocalizations.of(context)!.confirmDeleteMsg} \'${reminder.title}\'?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text(AppLocalizations.of(context)!.delete),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withAlpha(15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24.0),
          border: isSelected ? Border.all(color: Colors.redAccent, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              blurRadius: 24.0,
              offset: const Offset(0, 10.0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24.0),
          onTap: isSelecting
              ? () => provider.toggleSelection(reminder.id)
              : () => _navigateToEdit(context, reminder: reminder),
          onLongPress: () => provider.toggleSelection(reminder.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Opacity(
                    opacity: reminder.isEnabled ? 1.0 : 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              reminder.times.isEmpty
                                  ? AppLocalizations.of(context)!.noTime
                                  : _formatTime(reminder.times.first['hour']!, reminder.times.first['minute']!),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (reminder.times.length > 1) ...[
                              SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+ ${reminder.times.length - 1} ${AppLocalizations.of(context)!.more}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(icon, color: color, size: 14),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                reminder.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white54 : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (reminder.linkedGoalId != null && !isSelecting) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Goal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            if (isCustom && !isSelecting && reminder.linkedGoalId == null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.custom,
                                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isSelecting) ...[
                  const SizedBox(width: 16),
                  Switch(
                    value: reminder.isEnabled,
                    activeColor: primaryColor,
                    onChanged: (value) async {
                      await provider.toggleReminder(reminder, value);
                      if (value && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${reminder.title} reminder enabled'),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
