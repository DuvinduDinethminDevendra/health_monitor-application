import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/activity.dart';
import '../repositories/goal_repository.dart';
import '../repositories/activity_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final goals = await _goalRepo.getGoalsByUser(userId);
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  void _showAddEditBottomSheet({Goal? existingGoal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _GoalBottomSheet(
        existingGoal: existingGoal,
        onSave: (goal) async {
          if (existingGoal == null) {
            await _goalRepo.insertGoal(goal);
          } else {
            await _goalRepo.updateGoal(goal);
          }
          _loadGoals();
        },
      ),
    );
  }

  String _getBaseType(Goal goal) {
    if (goal.category.startsWith('Custom')) {
      return goal.title.toLowerCase();
    }
    return goal.category
        .replaceAll(' (Daily)', '')
        .replaceAll(' (Cumulative)', '')
        .toLowerCase();
  }

  Future<void> _updateProgress(Goal goal, double newProgress) async {
    // Determine the exact date to permanently anchor this manual progress
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser!.id!;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activityRepo = ActivityRepository();

    // Auto-Merge: Universally anchor manual progress to the Activity timeline
    bool isDaily = goal.category.contains('(Daily)');
    final typeMatch = _getBaseType(goal);

    double diff = 0.0;
    if (isDaily) {
      final activities =
          await activityRepo.getActivitiesByDateRange(userId, dateStr, dateStr);
      final goalActivities =
          activities.where((a) => a.type.toLowerCase() == typeMatch).toList();
      double currentDaySum =
          goalActivities.fold(0.0, (sum, a) => sum + a.value);
      diff = newProgress - currentDaySum;
    } else {
      diff = newProgress - goal.currentValue;
    }

    if (diff > 0) {
      // Insert the missing difference so the true historical Activity matches the manual input
      await activityRepo.insertActivity(Activity(
        userId: userId,
        type: typeMatch,
        value: diff,
        date: dateStr,
        duration: 0,
      ));
    }

    await _goalRepo.updateProgress(goal.id!, newProgress);
    if (newProgress >= goal.targetValue) {
      await _goalRepo.markCompleted(goal.id!);
    }
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.blueLagoon));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Health Goals',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.sapphire,
                fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.sapphire),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: () => _showAddEditBottomSheet(),
          backgroundColor: AppTheme.blueLagoon,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_rounded,
                      size: 80,
                      color: AppTheme.heather.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No goals set yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : AppTheme.sapphire,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to set your first goal',
                    style: TextStyle(color: AppTheme.heather),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                return _buildGoalCard(
                  goal: _goals[index],
                  onEdit: () =>
                      _showAddEditBottomSheet(existingGoal: _goals[index]),
                  onDelete: () async {
                    await _goalRepo.deleteGoal(_goals[index].id!);
                    _loadGoals();
                  },
                  onUpdateProgress: (val) => _updateProgress(_goals[index], val),
                );
              },
            ),
    );
  }

  Widget _buildGoalCard({
    required Goal goal,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Function(double) onUpdateProgress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
    final isCompleted = goal.currentValue >= goal.targetValue;
    Color accentColor = AppTheme.scooter; 

    final category = goal.category.toLowerCase();
    if (category.contains('sleep')) {
      accentColor = AppTheme.scooter;
    } else if (category.contains('water')) {
      accentColor = AppTheme.skyBlue;
    } else if (category.contains('step') || category.contains('walk')) {
      accentColor = AppTheme.blueLagoon;
    } else if (category.contains('diet') || category.contains('food')) {
      accentColor = AppTheme.warmOrange;
    }

    return MatteCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: onEdit,
                    color: isDark ? Colors.white60 : AppTheme.heather,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: onDelete,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.sapphire,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppTheme.sapphire,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 20),
          if (!isCompleted)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showProgressDialog(goal),
                icon: Icon(Icons.add_circle_outline, size: 18, color: accentColor),
                label: Text(
                  'Log Progress',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showProgressDialog(Goal goal) {
    final controller = TextEditingController(text: goal.currentValue.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.sapphire.withValues(alpha: 0.95) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Update ${goal.title}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
            const SizedBox(height: 12),
            Text('Current: ${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}', 
              style: TextStyle(color: AppTheme.heather, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
              decoration: InputDecoration(
                labelText: 'New Current Value (${goal.unit})',
                labelStyle: TextStyle(color: AppTheme.heather),
                prefixIcon: const Icon(Icons.edit_road_rounded, color: AppTheme.scooter),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.scooter)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? goal.currentValue;
                _updateProgress(goal, val);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blueLagoon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Save Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Bottom Sheet for Adding/Editing Goals
// ----------------------------------------------------------------------
class _GoalBottomSheet extends StatefulWidget {
  final Goal? existingGoal;
  final Function(Goal) onSave;

  const _GoalBottomSheet({this.existingGoal, required this.onSave});

  @override
  State<_GoalBottomSheet> createState() => _GoalBottomSheetState();
}

class _GoalBottomSheetState extends State<_GoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 7));
  String _selectedCategory = 'Steps (Daily)';
  String? _selectedReminderTime;

  final List<String> _categories = [
    'Steps (Daily)',
    'Steps (Cumulative)',
    'Running (Daily)',
    'Running (Cumulative)',
    'Sleep (Daily)',
    'Water (Daily)',
    'Diet (Daily)',
    'Custom (Daily)',
    'Custom (Cumulative)'
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingGoal?.title ?? '');
    _targetController = TextEditingController(
        text: widget.existingGoal?.targetValue.toString() ?? '');
    _unitController =
        TextEditingController(text: widget.existingGoal?.unit ?? '');

    if (widget.existingGoal != null) {
      _selectedDeadline = DateTime.parse(widget.existingGoal!.deadline);
      _selectedReminderTime = widget.existingGoal!.reminderTime;

      final existingCat = widget.existingGoal!.category;
      if (_categories.contains(existingCat)) {
        _selectedCategory = existingCat;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedReminderTime = picked.format(context));
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.id!;

      final goal = Goal(
        id: widget.existingGoal?.id,
        userId: userId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        targetValue: double.parse(_targetController.text.trim()),
        currentValue: widget.existingGoal?.currentValue ?? 0,
        unit: _unitController.text.trim(),
        deadline: _selectedDeadline.toIso8601String(),
        reminderTime: _selectedReminderTime,
        isCompleted: widget.existingGoal?.isCompleted ?? false,
      );

      widget.onSave(goal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.sapphire.withValues(alpha: 0.95) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text(widget.existingGoal == null ? 'Create New Goal' : 'Edit Goal', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  labelStyle: TextStyle(color: AppTheme.heather),
                  prefixIcon: const Icon(Icons.flag_outlined, color: AppTheme.scooter),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.scooter)),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? AppTheme.sapphire : Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Select Goal Category', 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 400,
                            child: ListView.separated(
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final cat = _categories[idx];
                                final isSelected = _selectedCategory == cat;
                                return ListTile(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    Navigator.pop(ctx);
                                  },
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.blueLagoon : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat.contains('Steps') ? Icons.directions_run_rounded :
                                      cat.contains('Running') ? Icons.speed_rounded :
                                      cat.contains('Sleep') ? Icons.bedtime_rounded :
                                      cat.contains('Water') ? Icons.water_drop_rounded :
                                      cat.contains('Diet') ? Icons.restaurant_rounded : Icons.flag_rounded,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[600]),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? AppTheme.blueLagoon : (isDark ? Colors.white70 : AppTheme.sapphire))),
                                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.blueLagoon) : null,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_rounded, color: AppTheme.blueLagoon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category / Tracking Type', style: TextStyle(fontSize: 12, color: AppTheme.heather)),
                            Text(_selectedCategory, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.sapphire)),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.heather),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        labelStyle: TextStyle(color: AppTheme.heather),
                        prefixIcon: const Icon(Icons.track_changes, color: AppTheme.scooter),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.scooter)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(color: AppTheme.heather),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.scooter)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('MMM dd, yyyy').format(_selectedDeadline)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: isDark ? Colors.white : AppTheme.sapphire,
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.alarm, size: 18),
                      label: Text(_selectedReminderTime ?? 'Set Reminder'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: isDark ? Colors.white : AppTheme.sapphire,
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueLagoon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  widget.existingGoal == null ? 'Create Goal' : 'Save Changes',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
