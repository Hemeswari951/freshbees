import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/style_profile_service.dart';
import '../../services/tryon_profile_service.dart';
import '../../models/profile_model.dart';
import '../../models/tryon_profile_model.dart';


class StyleProfileScreen extends StatefulWidget {
   final String? source;
   final TryOnProfile? profile;
   final ProfileModel? customerProfile;


  const StyleProfileScreen({super.key,this.source,this.profile,this.customerProfile,});

  @override
  State<StyleProfileScreen> createState() => _StyleProfileScreenState();
}

class _StyleProfileScreenState extends State<StyleProfileScreen> {
  String? _selectedSize;
String? _fitPreference;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final Set<String> _selectedColors = {};
  final Set<String> _selectedStyles = {};
  

  bool _isLoading = true;
  bool _isSaving = false;

  

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

  final List<String> _fitPreferences = [
  'Slim',
  'Regular',
  'Relaxed',
  'Oversized',
];

void _applyStyleData(Map<String, dynamic>? style) {
  if (style == null) return;

  setState(() {
    _selectedSize =
        style['apparel_size']?.toString();

    _fitPreference =
        style['fit_preference']?.toString();

    final colors =
        style['preferred_colors'];

    if (colors is List) {
      _selectedColors
        ..clear()
        ..addAll(
          colors.map((e) => e.toString()),
        );
    }

    final styles =
        style['preferred_styles'];

    if (styles is List) {
      _selectedStyles
        ..clear()
        ..addAll(
          styles.map((e) => e.toString()),
        );
    }
  });
}

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
    // =====================================================
    // ADDITIONAL TRY-ON PROFILE
    // =====================================================

    if (widget.profile != null) {
      final profileStyle =
          await TryOnProfileService.getProfileStyle(
        profileId: widget.profile!.profileId,
      );

      _applyStyleData(profileStyle);
    }

    // =====================================================
    // MAIN CUSTOMER
    // =====================================================

    else {
      final profile =
          await StyleProfileService.getProfile();

      _applyStyleData(profile);
    }
  } catch (e) {
    debugPrint(
      'Load Style Profile Error: $e',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> _saveAndContinue() async {
  if (_selectedSize == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select your usual size'),
      ),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    // =====================================================
    // ADDITIONAL TRY-ON PROFILE
    // =====================================================

    if (widget.profile != null) {
      await TryOnProfileService.saveProfileStyle(
        profileId: widget.profile!.profileId,
        apparelSize: _selectedSize,
        fitPreference: _fitPreference,
        preferredColors: _selectedColors.toList(),
        preferredStyles: _selectedStyles.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Style preferences saved successfully',
          ),
        ),
      );

      // If this profile is being edited from Try-On,
      // return to profile selection.
      if (widget.source == 'trial') {
        context.go('/virtual-tryon/select-profile');
        return;
      }

      // Otherwise return to the previous page.
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/profile');
      }

      return;
    }

    // =====================================================
    // MAIN CUSTOMER
    // =====================================================

    await StyleProfileService.saveProfile(
      apparelSize: _selectedSize,
      fitPreference: _fitPreference,
      preferredColors: _selectedColors.toList(),
      preferredStyles: _selectedStyles.toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Style preferences saved successfully',
        ),
      ),
    );

    // =====================================================
    // TRY-ON FLOW
    // =====================================================

    if (widget.source == 'trial') {
      context.go('/virtual-tryon/select-profile');
      return;
    }

    // =====================================================
    // PROFILE → STYLE PROFILE
    // =====================================================

    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/profile');
    }
  } catch (e) {
    debugPrint(
      'Save Style Profile Error: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to save style preferences: $e',
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
                'Personalize Your Style',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "We've already saved your basic details. Tell us a little about your style to personalize your experience.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
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

_sectionTitle('Fit Preference'),

const SizedBox(height: 14),

Wrap(
  spacing: 10,
  runSpacing: 10,
  children: _fitPreferences.map((fit) {
    return _choiceButton(
      label: fit,
      selected: _fitPreference == fit,
      onTap: () {
        setState(() {
          _fitPreference = fit;
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

  

  
}