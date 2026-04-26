/// Alert style for a reminder notification.
enum AlertStyle { banner, alarm }

class Reminder {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isEnabled;
  final AlertStyle alertStyle;
  final String repeatDays; // 7-char bitmask Mon→Sun, e.g. '1111111'
  final bool vibration;
  final String soundName; // 'default', 'gentle', 'urgent', 'silent'

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
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
      'hour': hour,
      'minute': minute,
      'is_enabled': isEnabled ? 1 : 0,
      'alert_style': alertStyle == AlertStyle.alarm ? 'alarm' : 'banner',
      'repeat_days': repeatDays,
      'vibration': vibration ? 1 : 0,
      'sound_name': soundName,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
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
    int? hour,
    int? minute,
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
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      alertStyle: alertStyle ?? this.alertStyle,
      repeatDays: repeatDays ?? this.repeatDays,
      vibration: vibration ?? this.vibration,
      soundName: soundName ?? this.soundName,
    );
  }
}
