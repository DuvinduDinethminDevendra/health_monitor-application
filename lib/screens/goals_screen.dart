import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/activity.dart';
import '../repositories/goal_repository.dart';
import '../repositories/activity_repository.dart';
import '../services/auth_service.dart';
import 'charts_screen.dart';

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
      backgroundColor: Colors.transparent,
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
    return goal.category.replaceAll(' (Daily)', '').replaceAll(' (Cumulative)', '').toLowerCase();
  }

  Future<void> _updateProgress(Goal goal, double newProgress) async {
    // Determine the exact date to permanently anchor this manual progress
    final userId = Provider.of<AuthService>(context, listen: false).currentUser!.id!;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activityRepo = ActivityRepository();
    
    // Auto-Merge: Universally anchor manual progress to the Activity timeline
    bool isDaily = goal.category.contains('(Daily)');
    final typeMatch = _getBaseType(goal);

    double diff = 0.0;
    if (isDaily) {
      final activities = await activityRepo.getActivitiesByDateRange(userId, dateStr, dateStr);
      final goalActivities = activities.where((a) => a.type.toLowerCase() == typeMatch).toList();
      double currentDaySum = goalActivities.fold(0.0, (sum, a) => sum + a.value);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'charts_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChartsScreen(initialIndex: 2)),
                );
              },
              backgroundColor: const Color(0xFF1A73E8),
              child: const Icon(Icons.show_chart, color: Colors.white),
            ),
            FloatingActionButton.extended(
              heroTag: 'add_goal_fab',
              onPressed: () => _showAddEditBottomSheet(),
              backgroundColor: const Color(0xFF00BFA5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Goal',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No goals set yet\nStart tracking your progress!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 100, left: 16, right: 16, top: 16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return _buildGoalCard(goal);
              },
            ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.progressPercent / 100;
    final isCompleted = goal.isCompleted || progress >= 1.0;

    // Premium Category Mappings
    IconData watermarkIcon = Icons.flag;
    Color cardColor = Colors.white;
    Color accentColor = const Color(0xFF1A73E8);

    final category = goal.category.toLowerCase();
    if (category.contains('sleep')) {
      watermarkIcon = Icons.nights_stay;
      cardColor = const Color(0xFFE8EAF6); // Very light indigo
      accentColor = const Color(0xFF3F51B5);
    } else if (category.contains('water')) {
      watermarkIcon = Icons.water_drop;
      cardColor = const Color(0xFFE1F5FE); // Very light blue
      accentColor = const Color(0xFF0288D1);
    } else if (category.contains('step') || category.contains('walk')) {
      watermarkIcon = Icons.directions_run;
      cardColor = const Color(0xFFE8F5E9); // Very light green
      accentColor = const Color(0xFF2E7D32);
    } else if (category.contains('diet') || category.contains('food')) {
      watermarkIcon = Icons.restaurant;
      cardColor = const Color(0xFFFFF3E0); // Very light orange
      accentColor = const Color(0xFFEF6C00);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                watermarkIcon,
                size: 120,
                color: accentColor.withOpacity(0.08),
              ),
            ),
            InkWell(
              onTap: () => _showAddEditBottomSheet(existingGoal: goal),
              child: Padding(
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
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            goal.category.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (goal.reminderTime != null && goal.reminderTime!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.alarm, size: 14, color: Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text(
                                  goal.reminderTime!,
                                  style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Circular Progress with Premium Look
                        SizedBox(
                          width: 65,
                          height: 65,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 4,
                                backgroundColor: Colors.transparent,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 7,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.white.withOpacity(0.4),
                                color: isCompleted ? Colors.green[600] : accentColor,
                              ),
                              Center(
                                child: isCompleted
                                    ? Icon(Icons.check_circle, color: Colors.green[700], size: 32)
                                    : Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: accentColor,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Goal Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black.withOpacity(0.85),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Deadline: ${DateFormat('MMM dd').format(DateTime.parse(goal.deadline))}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Action button
                    if (!isCompleted)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showProgressDialog(goal),
                          icon: Icon(Icons.add_circle_outline, size: 18, color: accentColor),
                          label: Text(
                            'Log Progress',
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: accentColor.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressDialog(Goal goal) {
    final controller =
        TextEditingController(text: goal.currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${goal.title}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current ${goal.unit}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? goal.currentValue;
              _updateProgress(goal, val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Handle Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.existingGoal == null ? 'Create New Goal' : 'Edit Goal',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Steps (Daily)',
                decoration: InputDecoration(
                  labelText: 'Category / Tracking Type',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Industry Standard Note:\n- Daily goals (e.g. 10,000 steps) reset every day.\n- Cumulative goals track total progress over time.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
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
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        prefixIcon: const Icon(Icons.track_changes),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g., km, kg',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                      label: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDeadline)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.existingGoal == null ? 'Create Goal' : 'Save Changes',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
