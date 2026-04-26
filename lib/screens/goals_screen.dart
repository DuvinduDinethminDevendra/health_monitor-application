import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../services/auth_service.dart';

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

  Future<void> _deleteGoal(Goal goal) async {
    await _goalRepo.deleteGoal(goal.id!);
    _loadGoals();
  }

  Future<void> _updateProgress(Goal goal, double newProgress) async {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  bottom: 80, left: 16, right: 16, top: 16),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAddEditBottomSheet(existingGoal: goal),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(goal.category),
                    backgroundColor: const Color(0xFFE3F2FD),
                    labelStyle: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  if (goal.reminderTime != null &&
                      goal.reminderTime!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.alarm, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(goal.reminderTime!,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey[200],
                          color: isCompleted
                              ? Colors.green
                              : const Color(0xFF1A73E8),
                        ),
                        Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Colors.green, size: 30)
                              : Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Goal Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(goal.deadline))}',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick action buttons
              if (!isCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Update Progress'),
                      onPressed: () => _showProgressDialog(goal),
                    ),
                  ],
                ),
            ],
          ),
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
  String _selectedCategory = 'General';
  String? _selectedReminderTime;
  String _customTrackingMethod = 'Cumulative'; // Default for custom

  final List<String> _categories = [
    'General',
    'Running',
    'Diet',
    'Water',
    'Sleep',
    'Workout',
    'Custom'
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
      if (existingCat.startsWith('Custom')) {
        _selectedCategory = 'Custom';
        _customTrackingMethod = existingCat.contains('(Daily)') ? 'Daily Reset' : 'Cumulative';
      } else {
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

      String finalCategory = _selectedCategory;
      if (_selectedCategory == 'Custom') {
        finalCategory = 'Custom (${_customTrackingMethod == 'Daily Reset' ? 'Daily' : 'Cumulative'})';
      }

      final goal = Goal(
        id: widget.existingGoal?.id,
        userId: userId,
        title: _titleController.text.trim(),
        category: finalCategory,
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
                value: _categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : 'General',
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              if (_selectedCategory == 'Custom') ...[
                DropdownButtonFormField<String>(
                  value: _customTrackingMethod,
                  decoration: InputDecoration(
                    labelText: 'Goal Tracking Method',
                    prefixIcon: const Icon(Icons.analytics_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    helperText: 'Cumulative builds up over time (like Weight Loss).\nDaily Reset starts at 0 each day (like Sleep or Water).',
                    helperMaxLines: 2,
                  ),
                  items: ['Cumulative', 'Daily Reset']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => _customTrackingMethod = val!),
                ),
                const SizedBox(height: 16),
              ],

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
