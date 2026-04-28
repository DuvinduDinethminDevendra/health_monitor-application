import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const HealthLogApp());
}

class HealthLogApp extends StatelessWidget {
  const HealthLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF14B8A6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          primary: const Color(0xFF14B8A6),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
      ),
      home: const HealthLogScreen(),
    );
  }
}

// --- DOMAIN LAYER ---

enum MeasurementUnit { metric, imperial }

class HealthLog {
  final String id;
  final double weight;
  final double height;
  final double bmi;
  final String bmiCategory;
  final String date;
  final List<String> tags;
  final String? notes;
  final MeasurementUnit unit;
  final double? waist;
  final double? hip;
  final double? chest;
  final double? bodyFat;

  HealthLog({
    required this.id,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bmiCategory,
    required this.date,
    required this.tags,
    this.notes,
    required this.unit,
    this.waist,
    this.hip,
    this.chest,
    this.bodyFat,
  });
}

// --- SERVICE LAYER ---
// This isolates the data logic so it can cleanly connect to the Auth and DB modules later.
class HealthDataService {
  final List<HealthLog> _logs = [];

  List<HealthLog> getAllLogs() {
    return List.unmodifiable(_logs);
  }

  void addLog(HealthLog log) {
    _logs.add(log);
    _logs.sort((a, b) => b.date.compareTo(a.date));
  }

  void updateLog(HealthLog updatedLog) {
    final index = _logs.indexWhere((l) => l.id == updatedLog.id);
    if (index != -1) {
      _logs[index] = updatedLog;
      _logs.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  void deleteLog(String id) {
    _logs.removeWhere((l) => l.id == id);
  }

  int getCurrentStreak() {
    if (_logs.isEmpty) return 0;
    
    final sortedLogs = List<HealthLog>.from(_logs)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    final uniqueDates = sortedLogs.map((l) => l.date).toSet().toList();
    if (uniqueDates.isEmpty) return 0;

    DateTime today = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(today);
    String yesterdayStr = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    int streak = 0;

    if (uniqueDates.first == todayStr || uniqueDates.first == yesterdayStr) {
      DateTime currentDate = DateTime.parse(uniqueDates.first);
      streak++;
      
      for (int i = 1; i < uniqueDates.length; i++) {
        DateTime prevDate = DateTime.parse(uniqueDates[i]);
        if (currentDate.difference(prevDate).inDays == 1) {
          streak++;
          currentDate = prevDate;
        } else {
          break;
        }
      }
    }
    return streak;
  }
}

// --- UI LAYER ---

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> with SingleTickerProviderStateMixin {
  final HealthDataService _healthService = HealthDataService();
  String _selectedFilter = 'All';
  MeasurementUnit _systemUnit = MeasurementUnit.metric;

  final List<String> _availableTags = [
    '🏋️ Post-Workout',
    '🛋️ Rest Day',
    '💧 Fasting',
    '🍔 Heavy Meal',
    '😫 High Stress',
    '🧘 Well Rested'
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --- BUSINESS LOGIC HELPER METHODS ---

  void _showSuccessOverlay(BuildContext context, int streak) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entry Saved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (streak > 0)
                          Text('🔥 $streak-Day Logging Streak!', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate()
             .slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack)
             .fadeIn(duration: 400.ms)
             .then(delay: 2500.ms)
             .slideY(begin: 0, end: -1, duration: 400.ms, curve: Curves.easeIn)
             .fadeOut(duration: 400.ms),
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(milliseconds: 3500), () {
      entry?.remove();
    });
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  double _calculateBMI(double weight, double height, MeasurementUnit unit) {
    if (unit == MeasurementUnit.metric) {
      final hm = height / 100;
      return double.parse((weight / (hm * hm)).toStringAsFixed(1));
    } else {
      // Imperial: (weight in lbs / (height in inches)^2 ) x 703
      return double.parse(((weight / (height * height)) * 703).toStringAsFixed(1));
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return const Color(0xFF0D9488);
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getBMIBackgroundColor(double bmi) {
    if (bmi < 18.5) return Colors.orange.shade50;
    if (bmi < 25) return const Color(0xFFCCFBF1);
    if (bmi < 30) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  String _getWeightLabel() => _systemUnit == MeasurementUnit.metric ? 'WEIGHT (KG)' : 'WEIGHT (LBS)';
  String _getHeightLabel() => _systemUnit == MeasurementUnit.metric ? 'HEIGHT (CM)' : 'HEIGHT (IN)';

  // --- MODALS ---

  void _showAddOrEditDialog({HealthLog? existingLog}) {
    final formKey = GlobalKey<FormState>();
    
    int weightInt = existingLog != null ? existingLog.weight.floor() : (_systemUnit == MeasurementUnit.metric ? 70 : 155);
    int weightDec = existingLog != null ? ((existingLog.weight - existingLog.weight.floor()) * 10).round() : 0;
    int heightVal = existingLog != null ? existingLog.height.round() : (_systemUnit == MeasurementUnit.metric ? 175 : 68);

    final notesController = TextEditingController(text: existingLog?.notes);
    final waistController = TextEditingController(text: existingLog?.waist?.toString() ?? '');
    final hipController = TextEditingController(text: existingLog?.hip?.toString() ?? '');
    final chestController = TextEditingController(text: existingLog?.chest?.toString() ?? '');
    final bodyFatController = TextEditingController(text: existingLog?.bodyFat?.toString() ?? '');

    final ValueNotifier<int> waistShake = ValueNotifier(0);
    final ValueNotifier<int> hipShake = ValueNotifier(0);
    final ValueNotifier<int> chestShake = ValueNotifier(0);
    final ValueNotifier<int> bodyFatShake = ValueNotifier(0);
    
    double previewBmi = existingLog?.bmi ?? _calculateBMI(weightInt + (weightDec / 10), heightVal.toDouble(), _systemUnit);
    DateTime selectedDate = existingLog != null ? DateTime.parse(existingLog.date) : DateTime.now();
    Set<String> selectedTags = existingLog?.tags.toSet() ?? {};
    bool isEditingTags = false;
    bool showAdvanced = existingLog?.waist != null || existingLog?.hip != null || existingLog?.chest != null || existingLog?.bodyFat != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildMeasurementField(String label, TextEditingController controller, ValueNotifier<int> shakeNotifier, String hint) {
            return ValueListenableBuilder<int>(
              valueListenable: shakeNotifier,
              builder: (context, shakeCount, child) {
                Widget field = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      onChanged: (val) {
                        if (val.contains('-') || (double.tryParse(val) != null && double.parse(val) < 0)) {
                          HapticFeedback.vibrate();
                          shakeNotifier.value += 1;
                          controller.text = val.replaceAll('-', '');
                          controller.selection = TextSelection.collapsed(offset: controller.text.length);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: hint,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
                      ),
                    ),
                  ],
                );
                if (shakeCount > 0) {
                  field = field.animate(key: ValueKey(shakeCount)).shake(hz: 8, duration: 300.ms);
                }
                return field;
              },
            );
          }

          void updateBmiPreview() {
            final w = weightInt + (weightDec / 10);
            final h = heightVal.toDouble();
            if (w > 0 && h > 0) {
              setDialogState(() {
                previewBmi = _calculateBMI(w, h, _systemUnit);
              });
            }
          }

          void showTagModal({String oldTag = '', bool isEdit = false}) {
            final tagController = TextEditingController(text: oldTag);
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(isEdit ? 'Edit Tag' : 'Add Custom Tag',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                content: TextField(
                  controller: tagController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g., 🍷 Drank Alcohol',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
                  ),
                ),
                actions: [
                  if (isEdit)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        setDialogState(() {
                          _availableTags.remove(oldTag);
                          selectedTags.remove(oldTag);
                          setState(() {});
                        });
                        Navigator.pop(dialogCtx);
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final newTag = tagController.text.trim();
                          if (newTag.isNotEmpty) {
                            setDialogState(() {
                              if (isEdit) {
                                if (newTag != oldTag) {
                                  final index = _availableTags.indexOf(oldTag);
                                  if (index != -1) _availableTags[index] = newTag;
                                  if (selectedTags.contains(oldTag)) {
                                    selectedTags.remove(oldTag);
                                    selectedTags.add(newTag);
                                  }
                                  setState(() {});
                                }
                              } else {
                                if (!_availableTags.contains(newTag)) _availableTags.add(newTag);
                                selectedTags.add(newTag);
                              }
                            });
                          }
                          Navigator.pop(dialogCtx);
                        },
                        child: Text(isEdit ? 'Save' : 'Add'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.92,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Form(
              key: formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingLog != null ? 'Edit Data' : 'Log Health Data',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weight and Height Pickers
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getWeightLabel(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CupertinoPicker.builder(
                                              scrollController: FixedExtentScrollController(initialItem: weightInt),
                                              itemExtent: 40,
                                              onSelectedItemChanged: (index) {
                                                HapticFeedback.selectionClick();
                                                weightInt = index;
                                                updateBmiPreview();
                                              },
                                              childCount: 700,
                                              itemBuilder: (context, index) => Center(child: Text(index.toString(), style: const TextStyle(fontSize: 20))),
                                            ),
                                          ),
                                          const Text('.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                          Expanded(
                                            child: CupertinoPicker.builder(
                                              scrollController: FixedExtentScrollController(initialItem: weightDec),
                                              itemExtent: 40,
                                              onSelectedItemChanged: (index) {
                                                HapticFeedback.selectionClick();
                                                weightDec = index;
                                                updateBmiPreview();
                                              },
                                              childCount: 10,
                                              itemBuilder: (context, index) => Center(child: Text(index.toString(), style: const TextStyle(fontSize: 20))),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getHeightLabel(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: CupertinoPicker.builder(
                                        scrollController: FixedExtentScrollController(initialItem: heightVal),
                                        itemExtent: 40,
                                        onSelectedItemChanged: (index) {
                                          HapticFeedback.selectionClick();
                                          heightVal = index;
                                          updateBmiPreview();
                                        },
                                        childCount: 300,
                                        itemBuilder: (context, index) => Center(child: Text(index.toString(), style: const TextStyle(fontSize: 20))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Real-Time BMI Gauge
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Estimated BMI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D9488))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: _getBMIBackgroundColor(previewBmi), borderRadius: BorderRadius.circular(20), border: Border.all(color: _getBMIColor(previewBmi))),
                                      child: Text(_getBMICategory(previewBmi).toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getBMIColor(previewBmi))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 150,
                                  child: SfRadialGauge(
                                    axes: <RadialAxis>[
                                      RadialAxis(
                                        minimum: 10,
                                        maximum: 40,
                                        showLabels: false,
                                        showTicks: false,
                                        axisLineStyle: const AxisLineStyle(thickness: 0.15, thicknessUnit: GaugeSizeUnit.factor),
                                        ranges: <GaugeRange>[
                                          GaugeRange(startValue: 10, endValue: 18.5, color: Colors.orange.withOpacity(0.8), startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                                          GaugeRange(startValue: 18.5, endValue: 25, color: const Color(0xFF0D9488).withOpacity(0.8), startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                                          GaugeRange(startValue: 25, endValue: 30, color: Colors.orange.withOpacity(0.8), startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                                          GaugeRange(startValue: 30, endValue: 40, color: Colors.red.withOpacity(0.8), startWidth: 0.15, endWidth: 0.15, sizeUnit: GaugeSizeUnit.factor),
                                        ],
                                        pointers: <GaugePointer>[
                                          NeedlePointer(
                                            value: previewBmi,
                                            enableAnimation: true,
                                            animationDuration: 1000,
                                            animationType: AnimationType.easeOutBack,
                                            needleColor: const Color(0xFF1E293B),
                                            knobStyle: const KnobStyle(color: Color(0xFF1E293B)),
                                          )
                                        ],
                                        annotations: <GaugeAnnotation>[
                                          GaugeAnnotation(
                                            widget: Text(previewBmi.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                                            angle: 90,
                                            positionFactor: 0.8,
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          const Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF14B8A6))), child: child!),
                              );
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF94A3B8), size: 20),
                                  const SizedBox(width: 12),
                                  Text(DateFormat('yyyy-MM-dd').format(selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                showAdvanced = !showAdvanced;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ADVANCED BODY METRICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  Icon(showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                          if (showAdvanced) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: buildMeasurementField('WAIST (${_systemUnit == MeasurementUnit.metric ? 'CM' : 'IN'})', waistController, waistShake, 'e.g. 80')),
                                const SizedBox(width: 16),
                                Expanded(child: buildMeasurementField('HIP (${_systemUnit == MeasurementUnit.metric ? 'CM' : 'IN'})', hipController, hipShake, 'e.g. 100')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: buildMeasurementField('CHEST (${_systemUnit == MeasurementUnit.metric ? 'CM' : 'IN'})', chestController, chestShake, 'e.g. 95')),
                                const SizedBox(width: 16),
                                Expanded(child: buildMeasurementField('BODY FAT (%)', bodyFatController, bodyFatShake, 'e.g. 15')),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CONTEXT & LIFESTYLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              InkWell(
                                onTap: () => setDialogState(() => isEditingTags = !isEditingTags),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(6)),
                                  child: Text(isEditingTags ? 'Done Editing' : 'Edit Tags', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: InkWell(
                                    onTap: () {
                                      if (isEditingTags) {
                                        showTagModal(oldTag: tag, isEdit: true);
                                      } else {
                                        setDialogState(() {
                                          if (isSelected) selectedTags.remove(tag);
                                          else selectedTags.add(tag);
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isEditingTags ? const Color(0xFFF1F5F9) : isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                                        border: Border.all(color: isEditingTags ? const Color(0xFFCBD5E1) : isSelected ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isEditingTags && isSelected) ...[const Icon(Icons.check, size: 16, color: Color(0xFF0F766E)), const SizedBox(width: 4)],
                                          Text(tag, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isEditingTags ? const Color(0xFF475569) : isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569))),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (!isEditingTags)
                                InkWell(
                                  onTap: () => showTagModal(),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                                        SizedBox(width: 4),
                                        Text('Add Custom', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('JOURNAL (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'How are you feeling today?',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            HapticFeedback.heavyImpact();
                            final w = weightInt + (weightDec / 10);
                            final h = heightVal.toDouble();
                            final bmi = _calculateBMI(w, h, _systemUnit);
                            
                            final log = HealthLog(
                              id: existingLog?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              weight: w,
                              height: h,
                              bmi: bmi,
                              bmiCategory: _getBMICategory(bmi),
                              date: DateFormat('yyyy-MM-dd').format(selectedDate),
                              tags: selectedTags.toList(),
                              notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              unit: _systemUnit,
                              waist: double.tryParse(waistController.text),
                              hip: double.tryParse(hipController.text),
                              chest: double.tryParse(chestController.text),
                              bodyFat: double.tryParse(bodyFatController.text),
                            );

                            setState(() {
                              if (existingLog != null) {
                                _healthService.updateLog(log);
                              } else {
                                _healthService.addLog(log);
                              }
                            });
                            
                            final currentStreak = _healthService.getCurrentStreak();
                            Navigator.pop(ctx);
                            _showSuccessOverlay(context, currentStreak);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(existingLog != null ? 'Update Health Data' : 'Save Health Data', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
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

  @override
  Widget build(BuildContext context) {
    final logs = _healthService.getAllLogs();
    
    final Set<String> allUsedTags = {};
    for (var log in logs) {
      allUsedTags.addAll(log.tags);
    }
    final filterOptions = ['All', ...allUsedTags.toList()..sort()];

    final filteredLogs = _selectedFilter == 'All'
        ? logs
        : logs.where((log) => log.tags.contains(_selectedFilter)).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Health Log', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Row(
                    children: [
                      // Unit Toggle Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _systemUnit = MeasurementUnit.metric),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _systemUnit == MeasurementUnit.metric ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _systemUnit == MeasurementUnit.metric ? Colors.white : const Color(0xFF64748B))),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _systemUnit = MeasurementUnit.imperial),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _systemUnit == MeasurementUnit.imperial ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('lbs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _systemUnit == MeasurementUnit.imperial ? Colors.white : const Color(0xFF64748B))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFCCFBF1), shape: BoxShape.circle),
                        child: Center(
                          child: Text(logs.length.toString(), style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            if (logs.isEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF0FDFA),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: const Color(0xFFCCFBF1).withOpacity(0.5), blurRadius: 24, spreadRadius: 8)],
                          ),
                          child: Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFCCFBF1).withOpacity(0.5)),
                              child: const Icon(Icons.monitor_weight_outlined, size: 48, color: Color(0xFF14B8A6)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('No health data logged yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      const Text('Start tracking your BMI journey.\nLog your weight and height to get insights.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B))),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddOrEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Log Your First Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: const Color(0xFF14B8A6).withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: filterOptions.map((opt) {
                          final isSelected = _selectedFilter == opt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedFilter = opt),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF14B8A6) : Colors.white,
                                  border: Border.all(color: isSelected ? const Color(0xFF14B8A6) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF14B8A6).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                ),
                                child: Text(opt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF475569))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Quick Stats
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LATEST ENTRY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        logs.first.weight.toString(),
                                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        logs.first.unit == MeasurementUnit.metric ? 'kg' : 'lbs',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('BMI: ${logs.first.bmi}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(border: Border.all(color: _getBMIColor(logs.first.bmi)), borderRadius: BorderRadius.circular(6)),
                                        child: Text(logs.first.bmiCategory.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getBMIColor(logs.first.bmi))),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              if (logs.length > 1) ...[
                                Builder(builder: (context) {
                                  // Find the previous log that matches the SAME unit so the translation "diff" makes sense
                                  final prevValidLog = logs.skip(1).where((l) => l.unit == logs.first.unit).firstOrNull;
                                  
                                  if (prevValidLog == null) return const SizedBox.shrink();

                                  final diff = logs.first.weight - prevValidLog.weight;
                                  final isGain = diff > 0;
                                  final isLoss = diff < 0;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLoss ? Colors.green.shade50 : isGain ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${isLoss ? '↓' : isGain ? '↑' : ''} ${diff.abs().toStringAsFixed(1)} ${logs.first.unit == MeasurementUnit.metric ? 'kg' : 'lbs'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isLoss ? Colors.green.shade600 : isGain ? Colors.red.shade600 : const Color(0xFF475569),
                                      ),
                                    ),
                                  );
                                })
                              ]
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: const [BoxShadow(color: Color(0x02000000), blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _getBMIBackgroundColor(log.bmi),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getBMIBackgroundColor(log.bmi)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          log.bmi.toString(),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getBMIColor(log.bmi)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${log.weight} ${log.unit == MeasurementUnit.metric ? 'kg' : 'lbs'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 2),
                                          Text('H: ${log.height} ${log.unit == MeasurementUnit.metric ? 'cm' : 'in'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(log.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _showAddOrEditDialog(existingLog: log),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() => _healthService.deleteLog(log.id));
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFFDA4AF)),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                if (log.waist != null || log.hip != null || log.chest != null || log.bodyFat != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (log.waist != null && log.hip != null && log.hip! > 0)
                                          _buildMetricColumn('W/H Ratio', (log.waist! / log.hip!).toStringAsFixed(2)),
                                        if (log.bodyFat != null)
                                          _buildMetricColumn('Body Fat', '${log.bodyFat}%'),
                                        if (log.chest != null)
                                          _buildMetricColumn('Chest', '${log.chest}${log.unit == MeasurementUnit.metric ? 'cm' : 'in'}'),
                                        if (log.waist != null && log.hip == null)
                                          _buildMetricColumn('Waist', '${log.waist}${log.unit == MeasurementUnit.metric ? 'cm' : 'in'}'),
                                      ],
                                    ),
                                  ),
                                ],
                                if (log.notes != null && log.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                                    child: Text('"${log.notes}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                                  )
                                ],
                                if (log.tags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: log.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                        child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                                      );
                                    }).toList(),
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: logs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddOrEditDialog(),
              backgroundColor: const Color(0xFF14B8A6),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }
}
