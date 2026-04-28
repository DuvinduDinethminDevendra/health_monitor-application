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
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    double? previewBmi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Log Health Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.darkCharcoal)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: const Icon(Icons.monitor_weight_rounded, color: AppTheme.skyBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (_) => updateBmiPreview(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: const Icon(Icons.height_rounded, color: AppTheme.skyBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (_) => updateBmiPreview(),
                ),
                if (previewBmi != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppTheme.emeraldGreen),
                        const SizedBox(width: 12),
                        Text(
                          'BMI: $previewBmi',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (weightController.text.isEmpty || heightController.text.isEmpty) return;
                    final userId = Provider.of<AuthService>(context, listen: false).currentUser!.id!;
                    final log = HealthLog(
                      userId: userId,
                      weight: double.parse(weightController.text),
                      height: double.parse(heightController.text),
                    );
                    await _healthRepo.insertHealthLog(log);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadLogs();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
      appBar: AppBar(
        title: const Text('Health Logs', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.darkCharcoal, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: AppTheme.skyBlue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final bmiColor = _getBmiColor(log.bmi);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: bmiColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0, top: 0, bottom: 0, width: 6,
                          child: Container(color: bmiColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: bmiColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  log.bmi.toString(),
                                  style: TextStyle(fontWeight: FontWeight.w800, color: bmiColor, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.bmiCategory.toUpperCase(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: bmiColor, letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${log.weight} kg • ${log.height} cm',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkCharcoal),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    log.date,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedGrey),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.5), size: 20),
                                    onPressed: () async {
                                      await _healthRepo.deleteHealthLog(log.id!);
                                      _loadLogs();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
