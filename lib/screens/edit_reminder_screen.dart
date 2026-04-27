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
  late TimeOfDay _selectedTime;
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
    _selectedTime = r != null
        ? TimeOfDay(hour: r.hour, minute: r.minute)
        : TimeOfDay.now();
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RemindersProvider>();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim().isNotEmpty
        ? _bodyController.text.trim()
        : 'Time for: $title';

    if (_isCreateMode) {
      await provider.addReminder(
        title: title,
        body: body,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        alertStyle: _alertStyle,
        repeatDays: _encodeDays(),
        vibration: _vibration,
        soundName: _soundName,
      );
    } else {
      final updated = widget.reminder!.copyWith(
        title: title,
        body: body,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
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
              ? '"$title" scheduled for ${_formatTime(_selectedTime)}'
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
    const accent = Color(0xFFAB47BC);

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
            // ── TIME PICKER ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Time'),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _formatTime(_selectedTime),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to change',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════════════════
            // ── TITLE & MESSAGE ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Details'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Take Vitamins',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'e.g. Don\'t skip your daily vitamins!',
                prefixIcon: const Icon(Icons.message_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════════════════
            // ── ALERT STYLE ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Alert Style'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _alertStyleCard(
                    icon: Icons.notifications_outlined,
                    label: 'Banner',
                    subtitle: 'Quiet notification',
                    style: AlertStyle.banner,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _alertStyleCard(
                    icon: Icons.alarm,
                    label: 'Alarm',
                    subtitle: 'Pop-up with sound',
                    style: AlertStyle.alarm,
                    accent: const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════════════════
            // ── REPEAT DAYS ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Repeat'),
            const SizedBox(height: 4),
            Text(
              _repeatSummary(),
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: active ? accent : Colors.grey.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? accent : Colors.grey.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: active ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════════════════
            // ── SOUND ──
            // ═══════════════════════════════════════════════════
            _sectionLabel('Sound'),
            const SizedBox(height: 8),
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
                        color: isActive ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(opt['label'] as String),
                    ],
                  ),
                  selected: isActive,
                  selectedColor: accent,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[700],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _soundName = opt['value'] as String),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════════════════
            // ── VIBRATION ──
            // ═══════════════════════════════════════════════════
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  _vibration ? 'Device will vibrate' : 'No vibration',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFAB47BC),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _alertStyleCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required AlertStyle style,
    required Color accent,
  }) {
    final isActive = _alertStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _alertStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? accent.withAlpha(20) : Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? accent : Colors.grey.withAlpha(50),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? accent : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? accent : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
