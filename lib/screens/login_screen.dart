import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final isNewUser = await authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      if (isNewUser) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errGoogleSignInFailed}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        color: isDark ? AppTheme.backgroundDark : AppTheme.alabaster,
        child: Center(
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
                    Icon(Icons.health_and_safety_rounded, size: 64, color: AppTheme.scooter),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.titleWelcomeBack,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.sapphire,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.descLogin,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
                    ),
                    SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.lblEmailAddress,
                        labelStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.heather),
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.scooter),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (value) => (value == null || !value.contains('@')) ? AppLocalizations.of(context)!.errInvalidEmail : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.sapphire),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.lblPassword,
                        labelStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.heather),
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.scooter),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.heather),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? AppLocalizations.of(context)!.errPasswordShort : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueLagoon,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppLocalizations.of(context)!.btnLogin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(AppLocalizations.of(context)!.btnNewAccount, style: const TextStyle(color: AppTheme.scooter, fontWeight: FontWeight.w900)),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey[300])),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(AppLocalizations.of(context)!.txtOr, style: const TextStyle(color: AppTheme.heather, fontWeight: FontWeight.bold))),
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey[300])),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppTheme.sapphire,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, size: 30),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.btnGoogleSignIn, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
