import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/style_profile_service.dart';
import '../../services/tryon_profile_service.dart';

class StyleProfileScreen extends StatefulWidget {
  const StyleProfileScreen({super.key});

  @override
  State<StyleProfileScreen> createState() => _StyleProfileScreenState();
}

class _StyleProfileScreenState extends State<StyleProfileScreen> {
  String? _gender;
  String? _ageGroup;
  String? _selectedSize;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final Set<String> _selectedColors = {};
  final Set<String> _selectedStyles = {};

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _ageGroups = [
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];

  final List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
  ];

  final List<String> _colors = [
    'Black',
    'White',
    'Beige',
    'Maroon',
    'Blue',
    'Green',
    'Pink',
    'Brown',
  ];

  final List<String> _styles = [
    'Traditional',
    'Casual',
    'Party Wear',
    'Formal',
    'Western',
    'Ethnic',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await StyleProfileService.getProfile();

      if (profile != null) {
        setState(() {
          _gender = profile['gender']?.toString();
          _ageGroup = profile['age_group']?.toString();
          _selectedSize = profile['size']?.toString();

          _heightController.text =
              profile['height_cm']?.toString() ?? '';

          _weightController.text =
              profile['weight_kg']?.toString() ?? '';

          final colors = profile['preferred_colors'];

          if (colors is List) {
            _selectedColors.addAll(
              colors.map((e) => e.toString()),
            );
          }

          final styles = profile['preferred_styles'];

          if (styles is List) {
            _selectedStyles.addAll(
              styles.map((e) => e.toString()),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Load Style Profile Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
  if (_gender == null ||
      _ageGroup == null ||
      _selectedSize == null ||
      _heightController.text.trim().isEmpty ||
      _weightController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete the required details'),
      ),
    );
    return;
  }

  final height = double.tryParse(
    _heightController.text.trim(),
  );

  final weight = double.tryParse(
    _weightController.text.trim(),
  );

  if (height == null || weight == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter valid height and weight'),
      ),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    // =====================================================
    // STEP 1: SAVE STYLE PROFILE
    // =====================================================

    await StyleProfileService.saveProfile(
      gender: _gender!,
      ageGroup: _ageGroup!,
      heightCm: height,
      weightKg: weight,
      size: _selectedSize!,
      preferredColors: _selectedColors.toList(),
      preferredStyles: _selectedStyles.toList(),
    );

    // =====================================================
    // STEP 2: CHECK WHETHER "ME" TRY-ON PROFILE EXISTS
    // =====================================================

    final profiles =
        await TryOnProfileService.getProfiles();

    TryOnProfile? meProfile;

    for (final profile in profiles) {
      if (profile.relationship.toLowerCase() == 'self' ||
          profile.profileName.toLowerCase() == 'me') {
        meProfile = profile;
        break;
      }
    }

    // =====================================================
    // STEP 3: CREATE "ME" PROFILE IF IT DOESN'T EXIST
    // =====================================================

    meProfile ??= await TryOnProfileService.createProfile(
        profileName: 'Me',
        relationship: 'Self',
        gender: _gender,
        age: _getAgeFromGroup(_ageGroup),
        size: _selectedSize,
        height: height,
        weight: weight,
        isDefault: true,
      );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your profile is ready. Add your photo to continue.',
        ),
      ),
    );

    // =====================================================
    // STEP 4: GO DIRECTLY TO PHOTO PAGE
    // =====================================================

    context.push(
      '/virtual-tryon/photo',
      extra: meProfile,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to save profile: $e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

int? _getAgeFromGroup(String? ageGroup) {
  switch (ageGroup) {
    case '18-24':
      return 21;

    case '25-34':
      return 29;

    case '35-44':
      return 39;

    case '45-54':
      return 49;

    case '55+':
      return 55;

    default:
      return null;
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () {
  context.go('/home');
},
        ),
        title: const Text(
          'Your Style Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us a little about you',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your preferences help us make your virtual try-on experience more personal.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Basic Information'),

              const SizedBox(height: 14),

              const Text(
                'Gender',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _choiceButton(
                    label: 'Female',
                    selected: _gender == 'Female',
                    onTap: () {
                      setState(() {
                        _gender = 'Female';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _choiceButton(
                    label: 'Male',
                    selected: _gender == 'Male',
                    onTap: () {
                      setState(() {
                        _gender = 'Male';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _choiceButton(
                    label: 'Prefer not to say',
                    selected: _gender == 'Prefer not to say',
                    onTap: () {
                      setState(() {
                        _gender = 'Prefer not to say';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Age Group',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              _dropdown(
                value: _ageGroup,
                hint: 'Select age group',
                items: _ageGroups,
                onChanged: (value) {
                  setState(() {
                    _ageGroup = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _heightController,
                      label: 'Height',
                      hint: '160',
                      suffix: 'cm',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _numberField(
                      controller: _weightController,
                      label: 'Weight',
                      hint: '55',
                      suffix: 'kg',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _sectionTitle('Your Usual Size'),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _sizes.map((size) {
                  return _choiceButton(
                    label: size,
                    selected: _selectedSize == size,
                    onTap: () {
                      setState(() {
                        _selectedSize = size;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              _sectionTitle('Preferred Colors'),

              const SizedBox(height: 8),

              const Text(
                'Choose the colors you usually love wearing.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((color) {
                  final selected =
                      _selectedColors.contains(color);

                  return FilterChip(
                    label: Text(color),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedColors.add(color);
                        } else {
                          _selectedColors.remove(color);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              _sectionTitle('Preferred Styles'),

              const SizedBox(height: 8),

              const Text(
                'Select the styles that match you.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _styles.map((style) {
                  final selected =
                      _selectedStyles.contains(style);

                  return FilterChip(
                    label: Text(style),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedStyles.add(style);
                        } else {
                          _selectedStyles.remove(style);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isSaving ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.black
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Colors.black
                : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.black12,
          ),
        ),
      ),
    );
  }
}