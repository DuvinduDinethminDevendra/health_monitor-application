import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'package:health_monitor/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<String> _availableTopics = [
    'Fitness', 'Diet', 'Meditation', 'Hydration', 
    'Weight Loss', 'Muscle Gain', 'Sleep', 'Running', 
    'Yoga', 'Healthy Habits'
  ];
  final List<String> _selectedTopics = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  Future<void> _register() async {
    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one topic!'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    if (error != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      _previousPage();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      final user = authService.currentUser;
      if (user != null) await authService.updateUserProfile(user.copyWith(interests: _selectedTopics));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        color: isDark ? AppTheme.backgroundDark : AppTheme.alabaster,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildCredentialsPage(isDark),
            _buildTopicsPage(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsPage(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MatteCard(
          padding: const EdgeInsets.all(32),
          color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, size: 64, color: AppTheme.scooter),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.createAccount, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire, letterSpacing: -1)),
                const SizedBox(height: 32),
                _buildField(_nameController, AppLocalizations.of(context)!.name, Icons.person_outline, isDark),
                const SizedBox(height: 16),
                _buildField(_emailController, AppLocalizations.of(context)!.email, Icons.email_outlined, isDark),
                const SizedBox(height: 16),
                _buildField(_passwordController, AppLocalizations.of(context)!.password, Icons.lock_outline, isDark, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                const SizedBox(height: 16),
                _buildField(_confirmPasswordController, AppLocalizations.of(context)!.confirmPassword, Icons.lock_outline, isDark, obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blueLagoon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.continueText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.alreadyAccount, style: TextStyle(color: AppTheme.scooter, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isDark, {bool? obscure, VoidCallback? onToggle}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ?? false,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.heather),
        prefixIcon: Icon(icon, color: AppTheme.scooter),
        suffixIcon: onToggle != null ? IconButton(icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility, color: AppTheme.heather), onPressed: onToggle) : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildTopicsPage(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MatteCard(
          padding: const EdgeInsets.all(32),
          color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.manageInterests, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.selectInterests, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _availableTopics.map((t) {
                  final sel = _selectedTopics.contains(t);
                  return FilterChip(
                    label: Text(_translateTopic(t)),
                    selected: sel,
                    onSelected: (s) => setState(() => s ? _selectedTopics.add(t) : _selectedTopics.remove(t)),
                    selectedColor: AppTheme.scooter,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: sel ? Colors.white : (isDark ? Colors.white70 : AppTheme.sapphire), fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  TextButton(onPressed: _isLoading ? null : _previousPage, child: Text(AppLocalizations.of(context)!.back, style: const TextStyle(color: AppTheme.heather, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueLagoon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppLocalizations.of(context)!.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateTopic(String topic) {
    final l10n = AppLocalizations.of(context)!;
    switch (topic.toLowerCase()) {
      case 'fitness': return l10n.fitness;
      case 'diet': return l10n.diet;
      case 'meditation': return l10n.meditation;
      case 'hydration': return l10n.hydration;
      case 'weight loss': return l10n.weightLoss;
      case 'muscle gain': return l10n.muscleGain;
      case 'sleep': return l10n.sleep;
      case 'running': return l10n.running;
      case 'yoga': return l10n.yoga;
      case 'healthy habits': return l10n.healthyHabits;
      default: return topic;
    }
  }
}
