import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../services/auth_service.dart';
import 'widgets/error_widget.dart';
import 'widgets/shimmer_loading.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  List<Goal> _goals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final goals = await _goalRepo.getGoalsByUser(userId);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load goals. Please try again.';
      });
    }
  }

  void _showAddEditDialog({Goal? existingGoal}) {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: existingGoal?.title ?? '');
    final targetController = TextEditingController(
        text: existingGoal?.targetValue.toString() ?? '');
    final currentController = TextEditingController(
        text: existingGoal?.currentValue.toString() ?? '0');
    final unitController =
        TextEditingController(text: existingGoal?.unit ?? '');
    DateTime deadline = existingGoal != null
        ? DateTime.parse(existingGoal.deadline)
        : DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      existingGoal != null ? 'Edit Goal' : 'New Goal',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g., Walk 10,000 steps daily',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Target',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'kg, km, steps',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    if (existingGoal != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: currentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Current Progress',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                          'Deadline: ${DateFormat('MMM dd, yyyy').format(deadline)}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => deadline = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final userId =
                                Provider.of<AuthService>(context, listen: false)
                                    .currentUser!
                                    .id!;
                            final goal = Goal(
                              id: existingGoal?.id,
                              userId: userId,
                              title: titleController.text,
                              targetValue: double.parse(targetController.text),
                              currentValue:
                                  double.tryParse(currentController.text) ?? 0,
                              unit: unitController.text,
                              deadline:
                                  DateFormat('yyyy-MM-dd').format(deadline),
                              isCompleted: existingGoal?.isCompleted ?? false,
                            );

                            if (existingGoal != null) {
                              await _goalRepo.updateGoal(goal);
                            } else {
                              await _goalRepo.insertGoal(goal);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadGoals();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB8C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(existingGoal != null ? 'Update Goal' : 'Create Goal', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 3);
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: AppErrorWidget(
          message: _errorMessage!,
          onRetry: _loadGoals,
        ),
      );
    }

    return Scaffold(
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB8C00).withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag, size: 80, color: Color(0xFFFB8C00)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No goals set yet',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first goal',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final progress = goal.progressPercent;
                final isOverdue =
                    DateTime.parse(goal.deadline).isBefore(DateTime.now());
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: goal.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (goal.isCompleted)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF00BFA5)),
                            PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  _showAddEditDialog(existingGoal: goal);
                                } else if (action == 'complete') {
                                  await _goalRepo.markCompleted(goal.id!);
                                  _loadGoals();
                                } else if (action == 'delete') {
                                  await _goalRepo.deleteGoal(goal.id!);
                                  _loadGoals();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                if (!goal.isCompleted)
                                  const PopupMenuItem(
                                      value: 'complete',
                                      child: Text('Mark Complete')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style:
                                            TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goal.isCompleted
                                  ? const Color(0xFF00BFA5)
                                  : const Color(0xFFFB8C00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progress.toStringAsFixed(0)}% complete',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                            Text(
                              'Due: ${goal.deadline}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue && !goal.isCompleted
                                    ? Colors.red
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_fab',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFFFB8C00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
