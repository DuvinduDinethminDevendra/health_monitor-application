import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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
            const SnackBar(
              content: Text('Profile Updated Successfully!'),
              backgroundColor: Color(0xFF00BFA5),
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Smart Profile',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.darkCharcoal,
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
          ? const Center(child: Text("User not found."))
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
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    // Editable Interests
                    const Text('Your Interests',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: _availableTopics.map((topic) {
                          final isSelected = _selectedInterests.contains(topic);
                          return FilterChip(
                            label: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppTheme.darkCharcoal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.emeraldGreen,
                            backgroundColor: AppTheme.glassWhite,
                            checkmarkColor: Colors.white,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(topic);
                              } else {
                                _selectedInterests.remove(topic);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Name cannot be empty' : null,
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
                              labelText: 'Age',
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
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.transgender),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Not Specified', 'Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g,
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
                              labelText: 'Height (cm)',
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
                              labelText: 'Weight (kg)',
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
                        child: const Text('Save Profile Data',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
