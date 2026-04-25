import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';

class RemindersProvider with ChangeNotifier {
  final ReminderRepository _repository = ReminderRepository();
  final NotificationService _notificationService = NotificationService();

  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  RemindersProvider() {
    loadReminders();
  }

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();

    _reminders = await _repository.getReminders();
    
    // Seed initial reminders if the database is empty
    if (_reminders.isEmpty) {
      final initialReminders = [
        Reminder(id: 1, title: 'Morning Workout', body: 'Time for your daily exercise routine!', hour: 7, minute: 0),
        Reminder(id: 2, title: 'Drink Water', body: 'Stay hydrated! Take a glass of water now.', hour: 9, minute: 0),
        Reminder(id: 3, title: 'Log Your Meals', body: 'Don\'t forget to log what you ate today.', hour: 12, minute: 30),
        Reminder(id: 4, title: 'Take a Walk', body: 'Get some fresh air! A 15-minute walk is great for your health.', hour: 15, minute: 0),
        Reminder(id: 5, title: 'Log Your Weight', body: 'Time to track your weight and BMI progress.', hour: 18, minute: 0),
        Reminder(id: 6, title: 'Bedtime Reminder', body: 'Time to wind down. A good night\'s sleep is essential!', hour: 22, minute: 0),
      ];

      for (var r in initialReminders) {
        await _repository.insertReminder(r);
      }
      _reminders = initialReminders;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleReminder(Reminder reminder, bool isEnabled) async {
    final updatedReminder = reminder.copyWith(isEnabled: isEnabled);
    
    // Update local state immediately for fast UI feedback
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      notifyListeners();
    }

    // Update DB
    await _repository.updateReminder(updatedReminder);

    if (isEnabled) {
      final granted = await _notificationService.requestPermissions();
      if (granted) {
        await _notificationService.scheduleDaily(
          id: updatedReminder.id,
          title: updatedReminder.title,
          body: updatedReminder.body,
          hour: updatedReminder.hour,
          minute: updatedReminder.minute,
        );
      } else {
        // If permission is denied, revert the state
        if (index != -1) {
          _reminders[index] = reminder;
          await _repository.updateReminder(reminder);
          notifyListeners();
        }
      }
    } else {
      await _notificationService.cancelNotification(reminder.id);
    }
  }
}
