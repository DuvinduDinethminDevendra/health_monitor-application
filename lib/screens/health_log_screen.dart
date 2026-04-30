import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';
import '../services/auth_service.dart';
import 'widgets/error_widget.dart';
import 'widgets/shimmer_loading.dart';
import 'widgets/liquid_health_indicator.dart';
import '../l10n/app_localizations.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen>
    with SingleTickerProviderStateMixin {
  final HealthLogRepository _healthRepo = HealthLogRepository();
  List<HealthLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  DateTime? _selectedViewDate;
  bool _isComparisonMode = false;
  String _systemUnit = 'metric';

  final List<String> _availableTags = [
    '🏋️ Post-Workout',
    '🛋️ Rest Day',
    '💧 Fasting',
    '🍔 Heavy Meal',
    '😫 High Stress',
    '🧘 Well Rested'
  ];

  // Empty state pulse animation
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

    _loadLogs();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.errLoadHealthLogs;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddOrEditDialog({HealthLog? existingLog}) {
    final formKey = GlobalKey<FormState>();

    int weightInt = existingLog != null
        ? existingLog.weight.floor()
        : (_systemUnit == 'metric' ? 70 : 155);
    int weightDec = existingLog != null
        ? ((existingLog.weight - existingLog.weight.floor()) * 10).round()
        : 0;
    int heightVal = existingLog != null
        ? existingLog.height.round()
        : (_systemUnit == 'metric' ? 175 : 68);

    final notesController = TextEditingController(text: existingLog?.notes);
    final waistController =
        TextEditingController(text: existingLog?.waist?.toString() ?? '');
    final hipController =
        TextEditingController(text: existingLog?.hip?.toString() ?? '');
    final chestController =
        TextEditingController(text: existingLog?.chest?.toString() ?? '');
    final bodyFatController =
        TextEditingController(text: existingLog?.bodyFat?.toString() ?? '');

    final ValueNotifier<int> waistShake = ValueNotifier(0);
    final ValueNotifier<int> hipShake = ValueNotifier(0);
    final ValueNotifier<int> chestShake = ValueNotifier(0);
    final ValueNotifier<int> bodyFatShake = ValueNotifier(0);

    double previewBmi = existingLog?.bmi ??
        HealthLog.calculateBmi(weightInt + (weightDec / 10),
            heightVal.toDouble(), _systemUnit);
    DateTime selectedDate =
        existingLog != null ? DateTime.parse(existingLog.date) : DateTime.now();
    Set<String> selectedTags = existingLog?.tags.toSet() ?? {};
    bool isEditingTags = false;
    bool showAdvanced = existingLog?.waist != null ||
        existingLog?.hip != null ||
        existingLog?.chest != null ||
        existingLog?.bodyFat != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          Widget buildMeasurementField(String label,
              TextEditingController controller,
              ValueNotifier<int> shakeNotifier,
              String hint) {
            return ValueListenableBuilder<int>(
              valueListenable: shakeNotifier,
              builder: (context, shakeCount, child) {
                Widget field = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            double? currentVal = double.tryParse(controller.text);
                            double suggestion = double.tryParse(hint) ?? 0;
                            
                            if (currentVal == null) {
                              // If empty, fill with suggestion
                              controller.text = suggestion % 1 == 0 ? suggestion.toInt().toString() : suggestion.toStringAsFixed(1);
                            } else {
                              // If not empty, decrement
                              double newVal = currentVal - 1;
                              if (newVal >= 0) {
                                controller.text = newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toStringAsFixed(1);
                              }
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8), size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              filled: true,
                              fillColor: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0)))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            double? currentVal = double.tryParse(controller.text);
                            double suggestion = double.tryParse(hint) ?? 0;
                            
                            if (currentVal == null) {
                              // If empty, fill with suggestion
                              controller.text = suggestion % 1 == 0 ? suggestion.toInt().toString() : suggestion.toStringAsFixed(1);
                            } else {
                              // If not empty, increment
                              double newVal = currentVal + 1;
                              controller.text = newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toStringAsFixed(1);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0D9488), size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                );
                if (shakeCount > 0) {
                  field = field
                      .animate(key: ValueKey(shakeCount))
                      .shake(hz: 8, duration: 300.ms);
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
                previewBmi = HealthLog.calculateBmi(w, h, _systemUnit);
              });
            }
          }

          void showTagModal({String oldTag = '', bool isEdit = false}) {
            final tagController = TextEditingController(text: oldTag);
            showDialog(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text(
                  isEdit ? AppLocalizations.of(context)!.btnEditTag : AppLocalizations.of(context)!.btnAddCustomTag,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: (isDark ? Colors.white : const Color(0xFF1E293B))),
                ),
                content: TextField(
                  controller: tagController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.hintCustomTag,
                    filled: true,
                    fillColor: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0)))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0D9488))),
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
                        });
                        Navigator.pop(dialogCtx);
                      },
                      icon: Icon(Icons.delete, size: 18),
                      label: Text(AppLocalizations.of(context)!.btnDelete),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text(AppLocalizations.of(context)!.btnCancel,
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isDark ? Colors.white : const Color(0xFF1E293B)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                                }
                              } else {
                                if (!_availableTags.contains(newTag)) {
                                  _availableTags.add(newTag);
                                }
                                selectedTags.add(newTag);
                              }
                            });
                          }
                          Navigator.pop(dialogCtx);
                        },
                        child: Text(isEdit ? AppLocalizations.of(context)!.btnSave : AppLocalizations.of(context)!.btnAdd),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                            color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              existingLog != null ? AppLocalizations.of(context)!.editData : AppLocalizations.of(context)!.logHealthData,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: (isDark ? Colors.white : const Color(0xFF1E293B))),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(Icons.close),
                              style: IconButton.styleFrom(
                                  backgroundColor: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                  foregroundColor: (isDark ? Colors.white70 : const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_getWeightLabel(),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: CupertinoPicker.builder(
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem: weightInt),
                                                  itemExtent: 40,
                                                  onSelectedItemChanged: (index) {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    weightInt = index;
                                                    updateBmiPreview();
                                                  },
                                                  childCount: 700,
                                                  itemBuilder: (context, index) =>
                                                      Center(
                                                          child: Text(
                                                              index.toString(),
                                                              style: TextStyle(
                                                                  fontSize: 20))),
                                                ),
                                              ),
                                              Text('.',
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                              Expanded(
                                                child: CupertinoPicker.builder(
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem: weightDec),
                                                  itemExtent: 40,
                                                  onSelectedItemChanged: (index) {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    weightDec = index;
                                                    updateBmiPreview();
                                                  },
                                                  childCount: 10,
                                                  itemBuilder: (context, index) =>
                                                      Center(
                                                          child: Text(
                                                              index.toString(),
                                                              style: const TextStyle(
                                                                  fontSize: 20))),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_getHeightLabel(),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                          ),
                                          child: CupertinoPicker.builder(
                                            scrollController:
                                                FixedExtentScrollController(
                                                    initialItem: heightVal),
                                            itemExtent: 40,
                                            onSelectedItemChanged: (index) {
                                              HapticFeedback.selectionClick();
                                              heightVal = index;
                                              updateBmiPreview();
                                            },
                                            childCount: 300,
                                            itemBuilder: (context, index) =>
                                                Center(
                                                    child: Text(index.toString(),
                                                        style: TextStyle(
                                                            fontSize: 20))),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFF0A2A3F).withOpacity(0.6) : Colors.white.withOpacity(0.6)),
                                  border: Border.all(
                                      color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
                                          .withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppLocalizations.of(context)!.estimatedBmi,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0D9488))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: _getBMIBackgroundColor(
                                                  previewBmi),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color:
                                                      _getBmiColor(previewBmi))),
                                          child: Text(
                                              HealthLog(
                                                      userId: '',
                                                      weight: 0,
                                                      height: 0,
                                                      bmi: previewBmi)
                                                  .bmiCategory
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _getBmiColor(previewBmi))),
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
                                            axisLineStyle: const AxisLineStyle(
                                                thickness: 0.15,
                                                thicknessUnit: GaugeSizeUnit.factor),
                                            ranges: <GaugeRange>[
                                              GaugeRange(
                                                  startValue: 10,
                                                  endValue: 18.5,
                                                  color: Colors.orange
                                                      .withOpacity(0.8),
                                                  startWidth: 0.15,
                                                  endWidth: 0.15,
                                                  sizeUnit: GaugeSizeUnit.factor),
                                              GaugeRange(
                                                  startValue: 18.5,
                                                  endValue: 25,
                                                  color: const Color(0xFF0D9488)
                                                      .withOpacity(0.8),
                                                  startWidth: 0.15,
                                                  endWidth: 0.15,
                                                  sizeUnit: GaugeSizeUnit.factor),
                                              GaugeRange(
                                                  startValue: 25,
                                                  endValue: 30,
                                                  color: Colors.orange
                                                      .withOpacity(0.8),
                                                  startWidth: 0.15,
                                                  endWidth: 0.15,
                                                  sizeUnit: GaugeSizeUnit.factor),
                                              GaugeRange(
                                                  startValue: 30,
                                                  endValue: 40,
                                                  color:
                                                      Colors.red.withOpacity(0.8),
                                                  startWidth: 0.15,
                                                  endWidth: 0.15,
                                                  sizeUnit: GaugeSizeUnit.factor),
                                            ],
                                            pointers: <GaugePointer>[
                                              NeedlePointer(
                                                value: previewBmi,
                                                enableAnimation: true,
                                                animationDuration: 1000,
                                                animationType:
                                                    AnimationType.easeOutBack,
                                                needleColor: (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                knobStyle: KnobStyle(
                                                    color: (isDark ? Colors.white : const Color(0xFF1E293B))),
                                              )
                                            ],
                                            annotations: <GaugeAnnotation>[
                                              GaugeAnnotation(
                                                widget: Text(previewBmi.toString(),
                                                    style: const TextStyle(
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0F766E))),
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
                              ).animate().fade().scale(
                                  duration: 400.ms, curve: Curves.easeOutBack),
                              SizedBox(height: 24),
                              Text(AppLocalizations.of(context)!.lblDate.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.light(
                                                primary: Color(0xFF0D9488))),
                                        child: child!),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                      color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      border: Border.all(
                                          color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: Color(0xFF94A3B8), size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(selectedDate),
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: (isDark ? Colors.white : const Color(0xFF1E293B)))),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(AppLocalizations.of(context)!.lblAdvancedMetrics,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text('NEW',
                                                    style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF166534))),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                              AppLocalizations.of(context)!.txtAdvancedMetrics,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF10B981))),
                                        ],
                                      ),
                                      Icon(
                                          showAdvanced
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: (isDark ? Colors.white70 : const Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ),
                              if (showAdvanced) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                        child: buildMeasurementField(
                                            '${AppLocalizations.of(context)!.lblWaist} (${_systemUnit == 'metric' ? 'CM' : 'IN'})',
                                            waistController,
                                            waistShake,
                                            _systemUnit == 'metric' ? '80' : '32')),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: buildMeasurementField(
                                            '${AppLocalizations.of(context)!.lblHip} (${_systemUnit == 'metric' ? 'CM' : 'IN'})',
                                            hipController,
                                            hipShake,
                                            _systemUnit == 'metric' ? '100' : '40')),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                        child: buildMeasurementField(
                                            '${AppLocalizations.of(context)!.lblChest} (${_systemUnit == 'metric' ? 'CM' : 'IN'})',
                                            chestController,
                                            chestShake,
                                            _systemUnit == 'metric' ? '95' : '38')),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: buildMeasurementField(
                                            '${AppLocalizations.of(context)!.lblBodyFat} (%)',
                                            bodyFatController,
                                            bodyFatShake,
                                            '15')),
                                  ],
                                ),
                              ],
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppLocalizations.of(context)!.lblContextLifestyle,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                  InkWell(
                                    onTap: () => setDialogState(
                                        () => isEditingTags = !isEditingTags),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDFA),
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                          isEditingTags
                                              ? AppLocalizations.of(context)!.btnEditTag
                                              : AppLocalizations.of(context)!.btnEditTag,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D9488))),
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
                                              if (isSelected) {
                                                selectedTags.remove(tag);
                                              } else {
                                                selectedTags.add(tag);
                                              }
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isEditingTags
                                                ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                                                : isSelected
                                                    ? const Color(0xFFF0FDFA)
                                                    : Colors.white,
                                            border: Border.all(
                                                color: isEditingTags
                                                    ? const Color(0xFFCBD5E1)
                                                    : isSelected
                                                        ? const Color(0xFF99F6E4)
                                                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isEditingTags && isSelected) ...[
                                                const Icon(Icons.check,
                                                    size: 16,
                                                    color: Color(0xFF0F766E)),
                                                const SizedBox(width: 4)
                                              ],
                                              Text(tag,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: isEditingTags
                                                          ? const Color(0xFF475569)
                                                          : isSelected
                                                              ? const Color(
                                                                  0xFF0F766E)
                                                              : const Color(
                                                                  0xFF475569))),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                                color: const Color(0xFFCBD5E1),
                                                style: BorderStyle.solid),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add,
                                                size: 16, color: (isDark ? Colors.white70 : const Color(0xFF64748B))),
                                            SizedBox(width: 4),
                                            Text('Add Custom',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Text('JOURNAL (OPTIONAL)',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                              SizedBox(height: 8),
                              TextField(
                                controller: notesController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'How are you feeling today?',
                                  filled: true,
                                  fillColor: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0)))),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Color(0xFF0D9488))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: Border(
                                top: BorderSide(color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))))),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                HapticFeedback.heavyImpact();
                                final userId = Provider.of<AuthService>(context,
                                        listen: false)
                                    .currentUser!
                                    .id!;
                                final w = weightInt + (weightDec / 10);
                                final h = heightVal.toDouble();

                                final log = HealthLog(
                                  id: existingLog?.id,
                                  userId: userId,
                                  weight: w,
                                  height: h,
                                  date: DateFormat('yyyy-MM-dd')
                                      .format(selectedDate),
                                  tags: selectedTags.toList(),
                                  notes: notesController.text.trim().isEmpty
                                      ? null
                                      : notesController.text.trim(),
                                  unit: _systemUnit,
                                  waist: double.tryParse(waistController.text),
                                  hip: double.tryParse(hipController.text),
                                  chest: double.tryParse(chestController.text),
                                  bodyFat:
                                      double.tryParse(bodyFatController.text),
                                );

                                if (existingLog != null) {
                                  await _healthRepo.updateHealthLog(log);
                                } else {
                                  await _healthRepo.insertHealthLog(log);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadLogs();
                                _showSuccessOverlay(context, _logs.length);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                                AppLocalizations.of(context)!.btnSave,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ).animate().scale(
                              duration: 400.ms, curve: Curves.easeOut),
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


  Widget _buildQuickStats(List<HealthLog> logs) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final latestLog = logs.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LATEST ENTRY',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF94A3B8))),
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
                        latestLog.weight.toString(),
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                            color: (isDark ? Colors.white : const Color(0xFF1E293B))),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        latestLog.unit == 'metric' ? 'kg' : 'lbs',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text('BMI: ${latestLog.bmi}',
                          style: TextStyle(
                              fontSize: 14, color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: _getBmiColor(latestLog.bmi)),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(latestLog.bmiCategory.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getBmiColor(latestLog.bmi))),
                      )
                    ],
                  )
                ],
              ),
              if (logs.length > 1) ...[
                Builder(builder: (context) {
                  final prevLog = logs[1];
                  if (prevLog.unit != latestLog.unit)
                    return const SizedBox.shrink();

                  final diff = latestLog.weight - prevLog.weight;
                  final isGain = diff > 0;
                  final isLoss = diff < 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLoss
                          ? Colors.green.shade50
                          : isGain
                              ? Colors.red.shade50
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${isLoss ? '↓' : isGain ? '↑' : ''} ${diff.abs().toStringAsFixed(1)} ${latestLog.unit == 'metric' ? 'kg' : 'lbs'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isLoss
                            ? Colors.green.shade600
                            : isGain
                                ? Colors.red.shade600
                                : const Color(0xFF475569),
                      ),
                    ),
                  );
                })
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Color _getBmiColor(double bmi) {
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

  void _showSuccessOverlay(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: (isDark ? Colors.white : const Color(0xFF1E293B)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entry Saved',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('Your health journey is being tracked!',
                            style: TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : const Color(0xFF1E293B)))),
      ],
    );
  }

  String _getWeightLabel() => _systemUnit == 'metric' ? 'WEIGHT (KG)' : 'WEIGHT (LBS)';
  String _getHeightLabel() => _systemUnit == 'metric' ? 'HEIGHT (CM)' : 'HEIGHT (IN)';

  Widget _buildFloatingMetric(String label, String value, IconData icon, {double? delta}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0A2A3F).withOpacity(0.9) : Colors.white.withOpacity(0.9)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0D9488)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8))),
                  if (delta != null && delta != 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${delta > 0 ? '+' : ''}${delta % 1 == 0 ? delta.toInt() : delta.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: delta > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isDark ? Colors.white : const Color(0xFF1E293B)))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    final filteredLogs = _selectedFilter == 'All' 
        ? _logs 
        : _logs.where((log) => log.tags.contains(_selectedFilter)).toList();

    final Set<String> allUsedTags = {};
    for (var log in _logs) {
      allUsedTags.addAll(log.tags);
    }
    final filterOptions = ['All', ...allUsedTags.toList()..sort()];

    return Scaffold(
      body: _logs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing icon container
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00BFA5).withAlpha(30),
                              const Color(0xFF1A73E8).withAlpha(20),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA5).withAlpha(15),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00BFA5).withAlpha(25),
                          ),
                          child: Icon(
                            Icons.monitor_weight_outlined,
                            size: 64,
                            color: Color(0xFF00BFA5),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'No health data logged yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Start tracking your BMI journey.\nLog your weight and height to get insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Call-to-action button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _showAddOrEditDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        label: const Text(
                          'Log Your First Entry',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedViewDate == null ? 'LATEST STATUS' : 'DAILY SNAPSHOT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  _selectedViewDate == null 
                                    ? 'Current Progress' 
                                    : DateFormat('MMMM dd, yyyy').format(_selectedViewDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (isDark ? Colors.white : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_logs.length > 1)
                                  IconButton(
                                    onPressed: () => setState(() => _isComparisonMode = !_isComparisonMode),
                                    icon: Icon(
                                      _isComparisonMode ? Icons.compare : Icons.compare_arrows,
                                      color: _isComparisonMode ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                    ),
                                    tooltip: 'Toggle Comparison',
                                  ),
                                if (_selectedViewDate != null)
                                  IconButton(
                                    onPressed: () => setState(() => _selectedViewDate = null),
                                    icon: Icon(Icons.history, color: Color(0xFF0D9488)),
                                    tooltip: 'Show Latest',
                                  ),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedViewDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedViewDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month, size: 18, color: (isDark ? Colors.white70 : const Color(0xFF64748B))),
                                        SizedBox(width: 6),
                                        Text('Pick Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(builder: (context) {
                      final displayIndex = _selectedViewDate == null 
                          ? (_logs.isNotEmpty ? 0 : -1)
                          : _logs.indexWhere(
                              (log) => log.date == DateFormat('yyyy-MM-dd').format(_selectedViewDate!));

                      final displayLog = displayIndex != -1 ? _logs[displayIndex] : null;
                      
                      HealthLog? comparisonLog;
                      if (_isComparisonMode && displayIndex != -1 && displayIndex + 1 < _logs.length) {
                        comparisonLog = _logs[displayIndex + 1];
                      }

                      if (displayLog == null && _selectedViewDate != null) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('No data for this date', style: TextStyle(color: (isDark ? Colors.white70 : const Color(0xFF64748B)), fontWeight: FontWeight.w500)),
                                  TextButton(
                                    onPressed: _showAddOrEditDialog,
                                    child: const Text('Add Log +', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (_selectedViewDate == null && !_isComparisonMode) _buildQuickStats(_logs),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  LiquidHealthIndicator(
                                    latestLog: displayLog,
                                    comparisonLog: comparisonLog,
                                  ),
                                  
                                  if (displayLog != null) ...[
                                    Positioned(
                                      left: 24,
                                      top: 75,
                                      child: _buildFloatingMetric('WAIST', 
                                        displayLog.waist != null ? '${displayLog.waist}${displayLog.unit == 'metric' ? 'cm' : 'in'}' : '--', 
                                        Icons.straighten,
                                        delta: (displayLog.waist != null && comparisonLog?.waist != null) 
                                            ? displayLog.waist! - comparisonLog!.waist! : null),
                                    ),
                                    Positioned(
                                      right: 24,
                                      top: 75,
                                      child: _buildFloatingMetric('HIPS', 
                                        displayLog.hip != null ? '${displayLog.hip}${displayLog.unit == 'metric' ? 'cm' : 'in'}' : '--', 
                                        Icons.accessibility_new,
                                        delta: (displayLog.hip != null && comparisonLog?.hip != null) 
                                            ? displayLog.hip! - comparisonLog!.hip! : null),
                                    ),
                                    Positioned(
                                      left: 24,
                                      bottom: 55,
                                      child: _buildFloatingMetric('CHEST', 
                                        displayLog.chest != null ? '${displayLog.chest}${displayLog.unit == 'metric' ? 'cm' : 'in'}' : '--', 
                                        Icons.fitbit,
                                        delta: (displayLog.chest != null && comparisonLog?.chest != null) 
                                            ? displayLog.chest! - comparisonLog!.chest! : null),
                                    ),
                                    Positioned(
                                      right: 24,
                                      bottom: 55,
                                      child: _buildFloatingMetric('BODY FAT', 
                                        displayLog.bodyFat != null ? '${displayLog.bodyFat}%' : '--', 
                                        Icons.percent,
                                        delta: (displayLog.bodyFat != null && comparisonLog?.bodyFat != null) 
                                            ? displayLog.bodyFat! - comparisonLog!.bodyFat! : null),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SliverPadding(padding: EdgeInsets.only(top: 8)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final log = filteredLogs[index];
                            final bmiColor = _getBmiColor(log.bmi);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x02000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getBMIBackgroundColor(log.bmi),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: _getBMIBackgroundColor(
                                                  log.bmi)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            log.bmi.toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: _getBmiColor(log.bmi)),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${log.weight} ${log.unit == 'metric' ? 'kg' : 'lbs'}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: (isDark ? Colors.white : const Color(0xFF1E293B)))),
                                            SizedBox(height: 2),
                                            Text(
                                                'H: ${log.height} ${log.unit == 'metric' ? 'cm' : 'in'}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(log.date,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF94A3B8))),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () =>
                                                    _showAddOrEditDialog(
                                                        existingLog: log),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(Icons.edit_outlined,
                                                      size: 18,
                                                      color: Color(0xFF94A3B8)),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  await _healthRepo
                                                      .deleteHealthLog(log.id!);
                                                  _loadLogs();
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color: Color(0xFFFDA4AF)),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  if (log.waist != null ||
                                      log.hip != null ||
                                      log.chest != null ||
                                      log.bodyFat != null) ...[
                                    SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (log.waist != null &&
                                              log.hip != null &&
                                              log.hip! > 0)
                                            _buildMetricColumn('W/H Ratio',
                                                (log.waist! / log.hip!)
                                                    .toStringAsFixed(2)),
                                          if (log.bodyFat != null)
                                            _buildMetricColumn(
                                                'Body Fat', '${log.bodyFat}%'),
                                          if (log.chest != null)
                                            _buildMetricColumn('Chest',
                                                '${log.chest}${log.unit == 'metric' ? 'cm' : 'in'}'),
                                          if (log.waist != null &&
                                              log.hip == null)
                                            _buildMetricColumn('Waist',
                                                '${log.waist}${log.unit == 'metric' ? 'cm' : 'in'}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (log.notes != null &&
                                      log.notes!.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)))),
                                      child: Text('"${log.notes}"',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: (isDark ? Colors.white70 : const Color(0xFF64748B)))),
                                    )
                                  ],
                                  if (log.tags.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: log.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                              border: Border.all(
                                                  color:
                                                      (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(tag,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF475569))),
                                        );
                                      }).toList(),
                                    )
                                  ]
                                ],
                              ),
                            );
              },
              childCount: filteredLogs.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'health_log_fab',
        onPressed: _showAddOrEditDialog,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
