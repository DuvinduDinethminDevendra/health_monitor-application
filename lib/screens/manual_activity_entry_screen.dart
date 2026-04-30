import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../services/auth_service.dart';
import '../theme/activity_theme.dart';
import '../l10n/app_localizations.dart';

class ManualActivityEntryScreen extends StatefulWidget {
  const ManualActivityEntryScreen({super.key});

  @override
  State<ManualActivityEntryScreen> createState() => _ManualActivityEntryScreenState();
}

class _ManualActivityEntryScreenState extends State<ManualActivityEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'steps';
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();
  final _customTypeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _types = ['steps', 'workout', 'running', 'cycling', 'swimming', 'yoga', 'custom'];

  @override
  void dispose() {
    _valueController.dispose();
    _durationController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final finalType = _type == 'custom' ? _customTypeController.text.trim().toLowerCase() : _type;
    final value = double.parse(_valueController.text);
    final duration = _durationController.text.isEmpty ? 0 : int.parse(_durationController.text);

    await provider.logManualActivity(userId, finalType, value, duration, _selectedDate);

    if (mounted) {
      setState(() => _isLoading = false);
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!), backgroundColor: ActivityTheme.error),
        );
        provider.clearError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgActivitySaved), backgroundColor: ActivityTheme.success),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.titleLogActivity),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ActivityTheme.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: InputDecoration(labelText: loc.lblActivityType),
                    items: _types.map((String value) {
                      String label = value[0].toUpperCase() + value.substring(1);
                      if (value == 'steps') label = 'Steps';
                      if (value == 'workout') label = 'Workout';
                      if (value == 'running') label = loc.activityTypeRunning;
                      if (value == 'cycling') label = loc.activityTypeCycling;
                      if (value == 'swimming') label = loc.activityTypeSwimming;
                      if (value == 'yoga') label = loc.activityTypeYoga;
                      if (value == 'custom') label = loc.activityTypeCustom;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (newValue) => setState(() => _type = newValue!),
                  ),
                ),
                
                if (_type == 'custom') ...[
                  const SizedBox(height: 16),
                  _buildCard(
                    child: TextFormField(
                      controller: _customTypeController,
                      decoration: InputDecoration(labelText: loc.lblCustomActivityName),
                      validator: (value) => value == null || value.isEmpty ? loc.reqField : null,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildCard(
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _type == 'steps' ? loc.lblNumSteps : loc.lblDistanceAmount,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return loc.reqField;
                      if (double.tryParse(value) == null) return loc.errValidNumber;
                      if (double.parse(value) < 0) return loc.errPositive;
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),
                _buildCard(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: loc.lblDurationMin),
                    validator: (value) {
                      if (value == null || value.isEmpty) return loc.reqField;
                      if (int.tryParse(value) == null) return loc.errValidInt;
                      if (int.parse(value) < 0) return loc.errPositive;
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),
                _buildCard(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: loc.lblDate),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ActivityTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(loc.btnSaveActivity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
