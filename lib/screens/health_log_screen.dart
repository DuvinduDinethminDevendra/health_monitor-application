import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:health_monitor/l10n/app_localizations.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  final HealthLogRepository _healthRepo = HealthLogRepository();
  List<HealthLog> _logs = [];
  bool _isLoading = true;

  double _siSize(double base) {
    if (!mounted) return base;
    try {
      final isSi = AppLocalizations.of(context)?.localeName == 'si';
      return isSi ? base * 0.85 : base;
    } catch (_) {
      return base;
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Text(AppLocalizations.of(context)!.logActivity, style: TextStyle(fontSize: _siSize(24), fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                const SizedBox(height: 24),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.weightKg,
                    labelStyle: TextStyle(color: AppTheme.heather),
                    prefixIcon: const Icon(Icons.monitor_weight_rounded, color: AppTheme.scooter),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.scooter)),
                  ),
                  onChanged: (_) => updateBmiPreview(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.heightCm,
                    labelStyle: TextStyle(color: AppTheme.heather),
                    prefixIcon: const Icon(Icons.height_rounded, color: AppTheme.scooter),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.scooter)),
                  ),
                  onChanged: (_) => updateBmiPreview(),
                ),
                if (previewBmi != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLagoon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${AppLocalizations.of(context)!.bmi} ${AppLocalizations.of(context)!.preview}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.sapphire)),
                        Text('$previewBmi', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.blueLagoon)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (weightController.text.isEmpty || heightController.text.isEmpty) return;
                    final userId = Provider.of<AuthService>(context, listen: false).currentUser!.id!;
                    final w = double.parse(weightController.text);
                    final h = double.parse(heightController.text);
                    final hm = h / 100;
                    final bmi = double.parse((w / (hm * hm)).toStringAsFixed(1));
                    
                    final log = HealthLog(
                      userId: userId,
                      weight: w,
                      height: h,
                      bmi: bmi,
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    );
                    await _healthRepo.insertHealthLog(log);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadLogs();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blueLagoon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getBmiColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return AppTheme.warmOrange;
      case 'normal':
        return AppTheme.scooter;
      case 'overweight':
        return AppTheme.warmOrange;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.blueLagoon));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.healthLog,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.sapphire,
                fontSize: _siSize(20))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.sapphire),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: AppTheme.blueLagoon,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart_rounded,
                      size: 80,
                      color: AppTheme.heather.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noLogs,
                    style: TextStyle(
                        fontSize: _siSize(18),
                        color: isDark ? Colors.white : AppTheme.sapphire,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.tapToAddLog,
                    style: TextStyle(color: AppTheme.heather),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final color = _getBmiColor(log.bmiCategory);
                return MatteCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translateBmiCategory(log.bmiCategory),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: _siSize(16),
                                color: isDark ? Colors.white : AppTheme.sapphire,
                              ),
                            ),
                            Text(
                              '${log.weight} kg • ${log.height} cm',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : AppTheme.heather,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              log.date,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${log.bmi}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: color,
                            ),
                          ),
                          Text(
                            'BMI',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey[400],
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            size: 18),
                        onPressed: () async {
                          await _healthRepo.deleteHealthLog(log.id!);
                          _loadLogs();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _translateBmiCategory(String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.toLowerCase()) {
      case 'underweight': return l10n.underweight;
      case 'normal': return l10n.normal;
      case 'overweight': return l10n.overweight;
      case 'obese': return l10n.obese;
      default: return category;
    }
  }
}
