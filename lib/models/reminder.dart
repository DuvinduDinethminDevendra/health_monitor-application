import 'dart:convert';

/// Alert style for a reminder notification.
enum AlertStyle { banner, alarm }

class Reminder {
  final int id;
  final String title;
  final String body;
  final List<Map<String, int>> times;
  final bool isEnabled;
  final AlertStyle alertStyle;
  final String repeatDays; // 7-char bitmask Mon→Sun, e.g. '1111111'
  final bool vibration;
  final String soundName; // 'default', 'gentle', 'urgent', 'silent'

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.times,
    this.isEnabled = false,
    this.alertStyle = AlertStyle.banner,
    this.repeatDays = '1111111',
    this.vibration = true,
    this.soundName = 'default',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'times': jsonEncode(times),
      'is_enabled': isEnabled ? 1 : 0,
      'alert_style': alertStyle == AlertStyle.alarm ? 'alarm' : 'banner',
      'repeat_days': repeatDays,
      'vibration': vibration ? 1 : 0,
      'sound_name': soundName,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    List<Map<String, int>> parsedTimes = [];
    if (map.containsKey('times') && map['times'] != null && map['times'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['times'] as String) as List;
        parsedTimes = decoded.map((e) => Map<String, int>.from(e as Map)).toList();
      } catch (e) {
        parsedTimes = [];
      }
    } else if (map.containsKey('hour') && map.containsKey('minute')) {
      // Legacy fallback migration
      parsedTimes = [{'hour': map['hour'] as int, 'minute': map['minute'] as int}];
    }

    return Reminder(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      times: parsedTimes,
      isEnabled: (map['is_enabled'] as int) == 1,
      alertStyle: (map['alert_style'] as String?) == 'alarm'
          ? AlertStyle.alarm
          : AlertStyle.banner,
      repeatDays: (map['repeat_days'] as String?) ?? '1111111',
      vibration: (map['vibration'] as int?) != 0,
      soundName: (map['sound_name'] as String?) ?? 'default',
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? body,
    List<Map<String, int>>? times,
    bool? isEnabled,
    AlertStyle? alertStyle,
    String? repeatDays,
    bool? vibration,
    String? soundName,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      times: times ?? this.times,
      isEnabled: isEnabled ?? this.isEnabled,
      alertStyle: alertStyle ?? this.alertStyle,
      repeatDays: repeatDays ?? this.repeatDays,
      vibration: vibration ?? this.vibration,
      soundName: soundName ?? this.soundName,
    );
  }
}
