import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  final HealthLogRepository _healthRepo = HealthLogRepository();
  List<HealthLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final logs = await _healthRepo.getHealthLogsByUser(userId);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    double? previewBmi;

    showDialog(
      context: context,
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

          return AlertDialog(
            title: const Text('Log Health Data',
                style: TextStyle(fontWeight: FontWeight.bold)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: const Icon(Icons.monitor_weight_rounded,
                            color: AppTheme.skyBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onChanged: (_) => updateBmiPreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0)
                          return 'Enter valid weight';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        prefixIcon: const Icon(Icons.height_rounded,
                            color: AppTheme.skyBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onChanged: (_) => updateBmiPreview(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0)
                          return 'Enter valid height';
                        return null;
                      },
                    ),
                    if (previewBmi != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color:
                                  AppTheme.emeraldGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calculate_rounded,
                                color: AppTheme.emeraldGreen),
                            const SizedBox(width: 12),
                            Text(
                              'BMI: $previewBmi',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
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
                  backgroundColor: AppTheme.skyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Log'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppTheme.warmOrange;
    if (bmi < 25) return AppTheme.emeraldGreen;
    if (bmi < 30) return AppTheme.warmOrange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight_rounded,
                      size: 80,
                      color: AppTheme.mutedGrey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'No health logs yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.darkCharcoal,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to log your health metrics',
                    style: TextStyle(color: AppTheme.mutedGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final bmiColor = _getBmiColor(log.bmi);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: bmiColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
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
                                'Weight: ${log.weight}kg • Height: ${log.height}cm',
                                style: TextStyle(
                                    color: AppTheme.darkCharcoal
                                        .withValues(alpha: 0.6),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(log.date,
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.mutedGrey)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: AppTheme.warmOrange),
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
    );
  }
}
