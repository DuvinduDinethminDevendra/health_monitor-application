import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/descenders_footer.dart';
import '../utils/ui_utils.dart';

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
      UIUtils.showNotification(context, AppLocalizations.of(context)!.errSelectTopic, isError: true);
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
      if (!mounted) return;
      UIUtils.showNotification(context, error, isError: true);
      _previousPage();
      return;
    }

    if (mounted) {
      final user = authService.currentUser;
      if (user != null) {
        await authService.updateUserProfile(user.copyWith(interests: _selectedTopics));
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const DashboardScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white70 : AppTheme.sapphire),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
              color: isDark ? Colors.white70 : AppTheme.sapphire),
            onPressed: () => authService.toggleTheme(),
          ),
          TextButton(
            onPressed: () => authService.setLocale(
              authService.locale.languageCode == 'en' ? const Locale('si') : const Locale('en')
            ),
            child: Text(
              authService.locale.languageCode == 'en' ? 'සිං' : 'EN',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.sapphire,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: isDark ? AppTheme.backgroundDark : AppTheme.alabaster,
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCredentialsPage(isDark),
              _buildTopicsPage(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsPage(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatteCard(
              padding: EdgeInsets.all(_siSize(32)),
              color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_rounded, size: 48, color: AppTheme.scooter),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.scooter.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppTheme.scooter.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Text(
                        'UPLIFT HEALTH',
                        style: TextStyle(
                          fontSize: _siSize(11),
                          fontWeight: FontWeight.w900,
                          color: AppTheme.scooter,
                          letterSpacing: 2.0,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.titleCreateAccount, 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _siSize(32), 
                        fontWeight: FontWeight.w900, 
                        color: isDark ? Colors.white : AppTheme.sapphire, 
                        letterSpacing: -1
                      )
                    ),
                    SizedBox(height: 32),
                    _buildField(_nameController, AppLocalizations.of(context)!.lblFullName, Icons.person_outline, isDark),
                    SizedBox(height: 16),
                    _buildField(_emailController, AppLocalizations.of(context)!.lblEmailAddress, Icons.email_outlined, isDark),
                    SizedBox(height: 16),
                    _buildField(_passwordController, AppLocalizations.of(context)!.lblPassword, Icons.lock_outline, isDark, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                    SizedBox(height: 16),
                    _buildField(_confirmPasswordController, AppLocalizations.of(context)!.lblConfirmPassword, Icons.lock_outline, isDark, obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    const SizedBox(height: 32),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 55, minWidth: double.infinity),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueLagoon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(AppLocalizations.of(context)!.btnContinue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.btnAlreadyAccount, style: const TextStyle(color: AppTheme.scooter, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const DescendersFooter(showCreatedBy: true),
            const SizedBox(height: 16),
          ],
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
      validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.reqField : null,
    );
  }

  Widget _buildTopicsPage(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatteCard(
              padding: EdgeInsets.all(_siSize(32)),
              color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.titleYourInterests, 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _siSize(28), 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : AppTheme.sapphire, 
                      letterSpacing: -1
                    )
                  ),
                  SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.descYourInterests, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
                  SizedBox(height: 32),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _availableTopics.map((t) {
                      final sel = _selectedTopics.contains(t);
                      return FilterChip(
                        label: Text(t),
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
                      TextButton(onPressed: _isLoading ? null : _previousPage, child: Text(AppLocalizations.of(context)!.btnBack, style: const TextStyle(color: AppTheme.heather, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 55),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.blueLagoon,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white) 
                              : Text(AppLocalizations.of(context)!.btnGetStarted, 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const DescendersFooter(showCreatedBy: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
