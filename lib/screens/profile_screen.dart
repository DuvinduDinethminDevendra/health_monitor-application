import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'package:health_monitor/l10n/app_localizations.dart';
import '../widgets/descenders_footer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  double _siSize(double base) {
    if (!mounted) return base;
    try {
      final isSi = AppLocalizations.of(context)?.localeName == 'si';
      return isSi ? base * 0.85 : base;
    } catch (_) {
      return base;
    }
  }

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _selectedGender = 'Not Specified';

  String? _base64Image;
  bool _isUploadingImage = false;

  List<String> _selectedInterests = [];
  final List<String> _availableTopics = [
    'Fitness',
    'Diet & Nutrition',
    'Mental Health',
    'Sleep Tracking',
    'Cardio',
    'Strength Training',
    'Yoga & Flexibility',
    'Running',
    'Weight Loss',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _heightController =
        TextEditingController(text: user?.height?.toString() ?? '');
    _weightController =
        TextEditingController(text: user?.weight?.toString() ?? '');
    _base64Image = user?.profilePicture;

    if (user?.gender != null &&
        ['Male', 'Female', 'Other'].contains(user?.gender)) {
      _selectedGender = user!.gender!;
    }

    if (user?.interests != null) {
      _selectedInterests = List.from(user!.interests!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70, // Compress to save SQLite space
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final String base64Str = base64Encode(bytes);

        if (!mounted) return;
        setState(() {
          _base64Image = base64Str;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          height: double.tryParse(_heightController.text.trim()),
          weight: double.tryParse(_weightController.text.trim()),
          gender: _selectedGender == 'Not Specified' ? null : _selectedGender,
          profilePicture: _base64Image,
          interests: _selectedInterests,
        );

        await authService.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileUpdated),
              backgroundColor: const Color(0xFF00BFA5),
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  void _showInterestsPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return MatteCard(
            padding: const EdgeInsets.all(32),
            borderRadius: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.heather.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(AppLocalizations.of(context)!.manageInterests, 
                  style: TextStyle(fontSize: _siSize(24), fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tailorExperience, 
                  style: TextStyle(color: isDark ? Colors.white60 : AppTheme.heather, fontSize: 14)),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _availableTopics.map((topic) {
                    final isSelected = _selectedInterests.contains(topic);
                    return ChoiceChip(
                      label: Text(_translateTopic(topic)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            _selectedInterests.add(topic);
                          } else {
                            _selectedInterests.remove(topic);
                          }
                        });
                        setState(() {}); // Update the main profile screen
                      },
                      selectedColor: AppTheme.scooter,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.sapphire),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.scooter,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.saveAndDone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
                SizedBox(height: 20),
                const Center(child: DescendersFooter(showCreatedBy: true)),
                const SizedBox(height: 8),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: _siSize(20))),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppTheme.darkCharcoal,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? Center(child: Text(AppLocalizations.of(context)!.userNotFound))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Editable Profile avatar using image_picker
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.glassWhite,
                              backgroundImage:
                                  _base64Image != null && _base64Image!.isNotEmpty
                                      ? MemoryImage(base64Decode(_base64Image!))
                                      : null,
                              child: _isUploadingImage
                                  ? const CircularProgressIndicator(color: AppTheme.emeraldGreen)
                                  : (_base64Image == null || _base64Image!.isEmpty
                                      ? const Icon(Icons.person,
                                          size: 60, color: AppTheme.mutedGrey)
                                      : null),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 16),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16, 
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                      // Theme Toggle Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.scooter.withOpacity(0.1) 
                              : AppTheme.blueLagoon.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.scooter.withOpacity(0.2) 
                                : AppTheme.blueLagoon.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Theme.of(context).brightness == Brightness.dark 
                                      ? Icons.dark_mode_rounded 
                                      : Icons.light_mode_rounded,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? AppTheme.scooter 
                                      : AppTheme.blueLagoon,
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.darkMode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      isDark ? AppLocalizations.of(context)!.solidMatteSapphire : AppLocalizations.of(context)!.solidMatteAlabaster,
                                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: isDark,
                              onChanged: (_) => authService.toggleTheme(),
                              activeColor: AppTheme.scooter,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                        // Language Toggle Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.scooter.withOpacity(0.1) 
                                : AppTheme.blueLagoon.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? AppTheme.scooter.withOpacity(0.2) 
                                  : AppTheme.blueLagoon.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.translate_rounded,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? AppTheme.scooter 
                                        : AppTheme.blueLagoon,
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context)!.language, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        authService.locale.languageCode == 'si' ? 'සිංහල (Sinhala)' : 'English',
                                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildLangBtn('EN', authService.locale.languageCode == 'en', () => authService.setLocale(const Locale('en'))),
                                  SizedBox(width: 8),
                                  _buildLangBtn('සිං', authService.locale.languageCode == 'si', () => authService.setLocale(const Locale('si'))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 32),
                      
                      Text(AppLocalizations.of(context)!.manageInterests, style: TextStyle(fontSize: _siSize(18), fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.sapphire)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ..._selectedInterests.map((topic) {
                            return Chip(
                              label: Text(_translateTopic(topic)),
                              backgroundColor: AppTheme.scooter.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: AppTheme.scooter,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                              side: BorderSide(color: AppTheme.scooter.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            );
                          }).toList(),
                          ActionChip(
                            avatar: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                            label: Text(AppLocalizations.of(context)!.addMore),
                            onPressed: _showInterestsPicker,
                            backgroundColor: AppTheme.blueLagoon,
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ],
                      ),
                    SizedBox(height: 32),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fullName,
                        prefixIcon: Icon(Icons.person_outline),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? AppLocalizations.of(context)!.nameEmpty : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.ageLabel,
                              prefixIcon: const Icon(Icons.cake),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.genderLabel,
                              prefixIcon: const Icon(Icons.transgender),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Not Specified', 'Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(_translateGender(g),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Height & Weight
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.heightCm,
                              prefixIcon: const Icon(Icons.height),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.weightKg,
                              prefixIcon: const Icon(Icons.fitness_center),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        child: Text(AppLocalizations.of(context)!.save,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DescendersFooter(showCreatedBy: true),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLangBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.scooter : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.scooter : AppTheme.heather.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppTheme.sapphire),
            fontWeight: FontWeight.w900,
            fontSize: 12,
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
      case 'diet & nutrition': return l10n.dietNutrition;
      case 'mental health': return l10n.mentalHealth;
      case 'sleep tracking': return l10n.sleepTracking;
      case 'cardio': return l10n.cardio;
      case 'strength training': return l10n.strengthTraining;
      case 'yoga & flexibility': return l10n.flexibility;
      default: return topic;
    }
  }

  String _translateGender(String gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender) {
      case 'Male': return l10n.male;
      case 'Female': return l10n.female;
      case 'Other': return l10n.other;
      case 'Not Specified': return l10n.notSpecified;
      default: return gender;
    }
  }
}
