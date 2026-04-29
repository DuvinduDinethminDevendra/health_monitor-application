import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../services/auth_service.dart';
import '../theme/activity_theme.dart';

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ActivityTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: ActivityTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
          const SnackBar(content: Text('Activity saved successfully!'), backgroundColor: ActivityTheme.success),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ActivityTheme.background,
      appBar: AppBar(
        title: const Text('Log Activity', style: TextStyle(color: ActivityTheme.textPrimary)),
        backgroundColor: ActivityTheme.cardBackground,
        iconTheme: const IconThemeData(color: ActivityTheme.textPrimary),
        elevation: 1,
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
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Activity Type'),
                    items: _types.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value[0].toUpperCase() + value.substring(1)),
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
                      decoration: const InputDecoration(labelText: 'Custom Activity Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildCard(
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _type == 'steps' ? 'Number of Steps' : 'Distance (km) / Amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Enter a valid number';
                      if (double.parse(value) < 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),
                _buildCard(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Enter a valid integer';
                      if (int.parse(value) < 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),
                _buildCard(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
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
                        : const Text('Save Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Container(
      decoration: BoxDecoration(
        color: ActivityTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
