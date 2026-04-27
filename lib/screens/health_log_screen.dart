import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';
import '../services/auth_service.dart';
import 'widgets/error_widget.dart';
import 'widgets/shimmer_loading.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  final HealthLogRepository _healthRepo = HealthLogRepository();
  List<HealthLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _healthRepo.getHealthLogsByUser(userId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load health logs. Please try again.';
      });
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    double? previewBmi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateBmiPreview() {
            final w = double.tryParse(weightController.text);
            final h = double.tryParse(heightController.text);
            if (w != null && h != null && h > 0) {
              final hm = h / 100;
              setDialogState(() {
                previewBmi = double.parse((w / (hm * hm)).toStringAsFixed(1));
              });
            }
          }

          return Container(
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
                      const Text(
                        'Log Health Data',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => updateBmiPreview(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) return 'Enter valid weight';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => updateBmiPreview(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) return 'Enter valid height';
                          return null;
                        },
                      ),
                      if (previewBmi != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calculate,
                                  color: Color(0xFF00BFA5)),
                              const SizedBox(width: 8),
                              Text(
                                'BMI: $previewBmi',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00BFA5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              final log = HealthLog(
                                userId: userId,
                                weight: double.parse(weightController.text),
                                height: double.parse(heightController.text),
                              );
                              await _healthRepo.insertHealthLog(log);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadLogs();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save Health Data', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return const Color(0xFF00BFA5);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 4);
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: AppErrorWidget(
          message: _errorMessage!,
          onRetry: _loadLogs,
        ),
      );
    }

    return Scaffold(
      body: _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monitor_weight, size: 80, color: Color(0xFF00BFA5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No health data logged yet',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to log your weight & height',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final bmiColor = _getBmiColor(log.bmi);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: bmiColor.withAlpha(30),
                          child: Text(
                            log.bmi.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: bmiColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.bmiCategory,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: bmiColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Weight: ${log.weight} kg • Height: ${log.height} cm',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(log.date,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              onPressed: () async {
                                await _healthRepo.deleteHealthLog(log.id!);
                                _loadLogs();
                              },
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
        heroTag: 'health_log_fab',
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
