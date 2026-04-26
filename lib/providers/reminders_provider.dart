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

  // ── Multi-select state ──
  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => _selectedIds;
  bool get isSelecting => _selectedIds.isNotEmpty;

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

  // ── Toggle On/Off ──
  Future<void> toggleReminder(Reminder reminder, bool isEnabled) async {
    final updatedReminder = reminder.copyWith(isEnabled: isEnabled);

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      notifyListeners();
    }

    await _repository.updateReminder(updatedReminder);

    if (isEnabled) {
      final granted = await _notificationService.requestPermissions();
      debugPrint('[RemindersProvider] Permission granted: $granted');
      debugPrint('[RemindersProvider] Alert style: ${updatedReminder.alertStyle}');
      if (granted) {
        // Confirmation notification — always uses banner (it's just a heads-up)
        await _notificationService.showNotification(
          id: updatedReminder.id + 10000,
          title: '✅ ${updatedReminder.title}',
          body: updatedReminder.alertStyle == AlertStyle.alarm
              ? '⏰ ALARM mode set! Daily at ${_formatTime(updatedReminder.hour, updatedReminder.minute)}. Lock your screen to test.'
              : '🔔 Banner reminder set for ${_formatTime(updatedReminder.hour, updatedReminder.minute)}.',
        );
        // Actual daily schedule — uses the chosen alert style (alarm or banner)
        await _notificationService.scheduleDaily(
          id: updatedReminder.id,
          title: updatedReminder.title,
          body: updatedReminder.body,
          hour: updatedReminder.hour,
          minute: updatedReminder.minute,
          alertStyle: updatedReminder.alertStyle,
          vibration: updatedReminder.vibration,
          soundName: updatedReminder.soundName,
        );
      } else {
        debugPrint('[RemindersProvider] Permission DENIED — reverting');
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

  // ── General-purpose update (from Edit screen) ──
  Future<void> updateReminder(Reminder updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reminders[index] = updated;
      notifyListeners();
    }

    await _repository.updateReminder(updated);

    // Reschedule if enabled
    if (updated.isEnabled) {
      await _notificationService.cancelNotification(updated.id);
      await _notificationService.scheduleDaily(
        id: updated.id,
        title: updated.title,
        body: updated.body,
        hour: updated.hour,
        minute: updated.minute,
        alertStyle: updated.alertStyle,
        vibration: updated.vibration,
        soundName: updated.soundName,
      );
    } else {
      await _notificationService.cancelNotification(updated.id);
    }
  }

  // ── Create ──
  Future<Reminder> addReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    AlertStyle alertStyle = AlertStyle.banner,
    String repeatDays = '1111111',
    bool vibration = true,
    String soundName = 'default',
  }) async {
    final maxId = _reminders.isEmpty
        ? 100
        : _reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b);
    final newId = maxId < 100 ? 101 : maxId + 1;

    final newReminder = Reminder(
      id: newId,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      isEnabled: true,
      alertStyle: alertStyle,
      repeatDays: repeatDays,
      vibration: vibration,
      soundName: soundName,
    );

    await _repository.insertReminder(newReminder);
    _reminders.add(newReminder);
    notifyListeners();

    final granted = await _notificationService.requestPermissions();
    if (granted) {
      await _notificationService.scheduleDaily(
        id: newReminder.id,
        title: newReminder.title,
        body: newReminder.body,
        hour: newReminder.hour,
        minute: newReminder.minute,
        alertStyle: newReminder.alertStyle,
        vibration: newReminder.vibration,
        soundName: newReminder.soundName,
      );
    }

    return newReminder;
  }

  // ── Delete single ──
  Future<void> deleteReminder(Reminder reminder) async {
    await _notificationService.cancelNotification(reminder.id);
    await _repository.deleteReminder(reminder.id);
    _reminders.removeWhere((r) => r.id == reminder.id);
    _selectedIds.remove(reminder.id);
    notifyListeners();
  }

  // ── Multi-select ──
  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_reminders.map((r) => r.id));
    notifyListeners();
  }

  Future<int> deleteSelected() async {
    final toDelete = _reminders.where((r) => _selectedIds.contains(r.id)).toList();
    for (final r in toDelete) {
      await _notificationService.cancelNotification(r.id);
      await _repository.deleteReminder(r.id);
    }
    _reminders.removeWhere((r) => _selectedIds.contains(r.id));
    final count = _selectedIds.length;
    _selectedIds.clear();
    notifyListeners();
    return count;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
