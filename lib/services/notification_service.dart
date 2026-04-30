import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();
  factory NotificationService() => _instance;

  /// Banner-style: quiet notification in the shade.
  static const _bannerChannel = AndroidNotificationDetails(
    'health_reminders_banner',
    'Health Reminders',
    channelDescription: 'Standard health reminder notifications',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
    autoCancel: true,
  );

  /// Alarm-style: rings continuously like a real alarm clock.
  /// FLAG_INSISTENT (4) = sound loops until user dismisses.
  /// audioAttributesUsage: alarm = uses alarm volume (louder).
  static final _alarmChannel = AndroidNotificationDetails(
    'health_reminders_alarm_v5',
    'Health Alarms',
    channelDescription: 'Urgent health alarms that ring continuously until dismissed',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
    autoCancel: false,
    ongoing: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500]),
    additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT — sound repeats
    timeoutAfter: 120000, // auto-stop after 2 minutes
    actions: <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'stop_alarm',
        'Stop',
        cancelNotification: true,
        showsUserInterface: true,
      ),
    ],
  );

  /// Returns the correct Android channel for the given settings.
  AndroidNotificationDetails _channelFor({
    AlertStyle alertStyle = AlertStyle.banner,
    bool vibration = true,
    String soundName = 'default',
  }) {
    if (alertStyle == AlertStyle.alarm) {
      return AndroidNotificationDetails(
        _alarmChannel.channelId,
        _alarmChannel.channelName,
        channelDescription: _alarmChannel.channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: soundName != 'silent',
        enableVibration: vibration,
        autoCancel: false,
        ongoing: true,
        vibrationPattern: vibration
            ? Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500])
            : null,
        additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
        timeoutAfter: 120000,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'stop_alarm',
            'Stop',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      );
    }
    // Banner: quiet, auto-dismisses
    return AndroidNotificationDetails(
      _bannerChannel.channelId,
      _bannerChannel.channelName,
      channelDescription: _bannerChannel.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      playSound: soundName != 'silent',
      enableVibration: vibration,
      autoCancel: true,
    );
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Detect and set the device's local timezone
    final String timeZoneName = _getDeviceTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('[NotificationService] Timezone set to: $timeZoneName');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
        android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(initSettings);
    debugPrint('[NotificationService] Initialized successfully');
  }

  String _getDeviceTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final Map<int, String> offsetMap = {
        330: 'Asia/Colombo',
        0: 'UTC',
        -300: 'America/New_York',
        -360: 'America/Chicago',
        -420: 'America/Denver',
        -480: 'America/Los_Angeles',
        60: 'Europe/London',
        120: 'Europe/Berlin',
        540: 'Asia/Tokyo',
        480: 'Asia/Singapore',
      };
      final offsetMinutes = offset.inMinutes;
      final mapped = offsetMap[offsetMinutes];
      if (mapped != null) return mapped;

      final dartTzName = now.timeZoneName;
      try {
        tz.getLocation(dartTzName);
        return dartTzName;
      } catch (_) {}

      debugPrint('[NotificationService] Unknown offset: $offsetMinutes min, falling back to UTC');
      return 'UTC';
    } catch (e) {
      debugPrint('[NotificationService] Timezone detection failed: $e');
      return 'UTC';
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final iosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      } else if (Platform.isAndroid) {
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted = await androidImplementation.requestNotificationsPermission();
          debugPrint('[NotificationService] Notification permission: $granted');
          // NOTE: We do NOT call requestExactAlarmsPermission() here because
          // it opens the System Settings app and blocks the entire flow.
          // The USE_EXACT_ALARM permission in the manifest is auto-granted.
          return granted ?? true;
        }
        return true; // Older Android — granted by default
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
      return true; // Optimistically try anyway
    }
  }

  /// Fires an immediate notification (for confirmation feedback).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    AlertStyle alertStyle = AlertStyle.banner,
    bool vibration = true,
    String soundName = 'default',
  }) async {
    try {
      final androidDetails = _channelFor(
        alertStyle: alertStyle,
        vibration: vibration,
        soundName: soundName,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _notifications.show(id, title, body, details);
      debugPrint('[NotificationService] Shown: "$title" (${alertStyle.name})');
    } catch (e) {
      debugPrint('[NotificationService] ERROR showing: $e');
    }
  }

  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required int hour,
    required int minute,
    AlertStyle alertStyle = AlertStyle.banner,
    bool vibration = true,
    String soundName = 'default',
  }) async {
    try {
      final scheduledDate = tz.TZDateTime(
          tz.local, date.year, date.month, date.day, hour, minute);

      debugPrint('[NotificationService] Scheduling ONCE "$title" (id=$id) at $scheduledDate');

      final androidDetails = _channelFor(
        alertStyle: alertStyle,
        vibration: vibration,
        soundName: soundName,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('[NotificationService] ✓ Scheduled once successfully');
    } catch (e) {
      debugPrint('[NotificationService] ✗ ERROR scheduling once: $e');
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    AlertStyle alertStyle = AlertStyle.banner,
    bool vibration = true,
    String soundName = 'default',
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint('[NotificationService] Scheduling "$title" (id=$id, style=${alertStyle.name}) at $scheduledDate');

      final androidDetails = _channelFor(
        alertStyle: alertStyle,
        vibration: vibration,
        soundName: soundName,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[NotificationService] ✓ Scheduled successfully');
    } catch (e) {
      debugPrint('[NotificationService] ✗ ERROR scheduling: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('[NotificationService] Cancelled id=$id');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('[NotificationService] All cancelled');
  }
}
