import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminders_provider.dart';

class EditReminderScreen extends StatefulWidget {
  /// Pass an existing reminder to edit, or null to create a new one.
  final Reminder? reminder;

  const EditReminderScreen({super.key, this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late List<TimeOfDay> _selectedTimes;
  late AlertStyle _alertStyle;
  late List<bool> _repeatDays; // Mon–Sun, 7 items
  late bool _vibration;
  late String _soundName;
  final _formKey = GlobalKey<FormState>();

  bool get _isCreateMode => widget.reminder == null;
  bool get _isCustom => widget.reminder == null || widget.reminder!.id > 6;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _soundOptions = [
    {'value': 'default', 'label': 'Default', 'icon': Icons.music_note},
    {'value': 'gentle', 'label': 'Gentle', 'icon': Icons.spa},
    {'value': 'urgent', 'label': 'Urgent', 'icon': Icons.warning_amber},
    {'value': 'silent', 'label': 'Silent', 'icon': Icons.volume_off},
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _bodyController = TextEditingController(text: r?.body ?? '');
    _selectedTimes = r != null && r.times.isNotEmpty
        ? r.times.map((t) => TimeOfDay(hour: t['hour']!, minute: t['minute']!)).toList()
        : [TimeOfDay.now()];
    _alertStyle = r?.alertStyle ?? AlertStyle.banner;
    _repeatDays = _parseDays(r?.repeatDays ?? '1111111');
    _vibration = r?.vibration ?? true;
    _soundName = r?.soundName ?? 'default';
  }

  List<bool> _parseDays(String bitmask) {
    return List.generate(7, (i) => i < bitmask.length && bitmask[i] == '1');
  }

  String _encodeDays() {
    return _repeatDays.map((d) => d ? '1' : '0').join();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _repeatSummary() {
    final all = _repeatDays.every((d) => d);
    final none = _repeatDays.every((d) => !d);
    if (all) return 'Every day';
    if (none) return 'Never';
    final weekdays = _repeatDays.sublist(0, 5).every((d) => d) &&
        !_repeatDays[5] &&
        !_repeatDays[6];
    if (weekdays) return 'Weekdays';
    final weekends = !_repeatDays.sublist(0, 5).any((d) => d) &&
        _repeatDays[5] &&
        _repeatDays[6];
    if (weekends) return 'Weekends';
    final names = <String>[];
    for (int i = 0; i < 7; i++) {
      if (_repeatDays[i]) names.add(_dayNames[i]);
    }
    return names.join(', ');
  }

  Future<void> _pickTime({int? index}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: index != null ? _selectedTimes[index] : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (index != null) {
          _selectedTimes[index] = picked;
        } else {
          _selectedTimes.add(picked);
        }
      });
    }
  }

  void _removeTime(int index) {
    if (_selectedTimes.length > 1) {
      setState(() => _selectedTimes.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must have at least one time scheduled.')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RemindersProvider>();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim().isNotEmpty
        ? _bodyController.text.trim()
        : 'Time for: $title';
    final mappedTimes = _selectedTimes.map((t) => {'hour': t.hour, 'minute': t.minute}).toList();

    if (_isCreateMode) {
      await provider.addReminder(
        title: title,
        body: body,
        times: mappedTimes,
        alertStyle: _alertStyle,
        repeatDays: _encodeDays(),
        vibration: _vibration,
        soundName: _soundName,
      );
    } else {
      final updated = widget.reminder!.copyWith(
        title: title,
        body: body,
        times: mappedTimes,
        alertStyle: _alertStyle,
        repeatDays: _encodeDays(),
        vibration: _vibration,
        soundName: _soundName,
      );
      await provider.updateReminder(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCreateMode
              ? '"$title" scheduled'
              : '"$title" updated'),
          backgroundColor: const Color(0xFFAB47BC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete \'${widget.reminder!.title}\'?'),
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

    if (confirmed == true && mounted) {
      await context.read<RemindersProvider>().deleteReminder(widget.reminder!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.reminder!.title}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'New Reminder' : 'Edit Reminder'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ═══════════════════════════════════════════════════
            // ── SCHEDULE TIMES ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Schedule'),
            SizedBox(height: 8),
            ...List.generate(_selectedTimes.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: accent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    _formatTime(_selectedTimes[index]),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1.0, color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => _removeTime(index),
                  ),
                  onTap: () => _pickTime(index: index),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            }),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () => _pickTime(),
                icon: Icon(Icons.add, color: accent),
                label: Text('Add Time', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── TITLE & MESSAGE ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Details'),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  labelText: 'Title',
                  hintText: 'e.g. Take Vitamins',
                  prefixIcon: Icon(Icons.label_outline, color: Colors.grey),
                  border: InputBorder.none,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
            ),
            SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _bodyController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  labelText: 'Message (optional)',
                  hintText: 'e.g. Don\'t skip your daily vitamins!',
                  prefixIcon: const Icon(Icons.message_outlined, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── ALERT STYLE ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Alert Style'),
            SizedBox(height: 8),
            Container(
              height: 56,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _alertStyle = AlertStyle.banner),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _alertStyle == AlertStyle.banner ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: _alertStyle == AlertStyle.banner ? [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            'Banner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _alertStyle == AlertStyle.banner ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _alertStyle = AlertStyle.alarm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _alertStyle == AlertStyle.alarm ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: _alertStyle == AlertStyle.alarm ? [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            'Alarm',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _alertStyle == AlertStyle.alarm ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── REPEAT DAYS ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Repeat'),
            SizedBox(height: 4),
            Text(
              _repeatSummary(),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[500]),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = _repeatDays[i];
                return GestureDetector(
                  onTap: () => setState(() => _repeatDays[i] = !_repeatDays[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active ? accent.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? accent.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: active ? accent : (isDark ? Colors.white54 : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── SOUND ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Sound'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _soundOptions.map((opt) {
                final isActive = _soundName == opt['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        size: 16,
                        color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                      SizedBox(width: 6),
                      Text(opt['label'] as String),
                    ],
                  ),
                  selected: isActive,
                  selectedColor: accent.withOpacity(0.1),
                  backgroundColor: Colors.transparent,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isActive ? accent : (isDark ? Colors.white60 : Colors.grey[600]),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  onSelected: (_) => setState(() => _soundName = opt['value'] as String),
                );
              }).toList(),
            ),
            SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── VIBRATION ──
            // ═══════════════════════════════════════════════════
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: Text('Vibration', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  _vibration ? 'Device will vibrate' : 'No vibration',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[500]),
                ),
                secondary: Icon(
                  _vibration ? Icons.vibration : Icons.phone_android,
                  color: _vibration ? accent : Colors.grey,
                ),
                activeColor: accent,
                value: _vibration,
                onChanged: (v) => setState(() => _vibration = v),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════
            // ── SAVE BUTTON ──
            // ═══════════════════════════════════════════════════
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isCreateMode ? Icons.check_circle_outline : Icons.save_outlined),
                label: Text(
                  _isCreateMode ? 'Create Reminder' : 'Save Changes',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),

            // ═══════════════════════════════════════════════════
            // ── DELETE BUTTON (edit mode only) ──
            // ═══════════════════════════════════════════════════
            if (!_isCreateMode) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text(
                    'Delete Reminder',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }


}
