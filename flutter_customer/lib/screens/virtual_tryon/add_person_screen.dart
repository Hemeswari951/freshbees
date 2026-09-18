import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tryon_profile_service.dart';
import '../../models/tryon_profile_model.dart';

class AddPersonScreen extends StatefulWidget {
  final TryOnProfile? profile;
  const AddPersonScreen({super.key,this.profile,});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _relationship;
  String? _gender;
  DateTime? _dateOfBirth;
  String? _size;

  @override
void initState() {
  super.initState();

  final profile = widget.profile;

  if (profile != null) {
    _nameController.text = profile.profileName;
    _heightController.text =
        profile.height?.toString() ?? '';
    _weightController.text =
        profile.weight?.toString() ?? '';

    _relationship = profile.relationship;
    _gender = profile.gender;
    _size = profile.size;

    if (profile.dateOfBirth != null &&
        profile.dateOfBirth!.isNotEmpty) {
      _dateOfBirth = DateTime.tryParse(
        profile.dateOfBirth!,
      );
    }
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _savePerson() async {
  if (_nameController.text.trim().isEmpty ||
      _relationship == null ||
      _gender == null ||
      _dateOfBirth == null ||
      _size == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all required fields'),
      ),
    );
    return;
  }

  try {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final existingProfile = widget.profile;

    if (existingProfile != null) {
      // =====================================================
      // EDIT EXISTING TRY-ON PROFILE
      // =====================================================

      final updatedProfile =
          await TryOnProfileService.updateProfile(
        profileId: existingProfile.profileId,
        profileName: _nameController.text.trim(),
        relationship: _relationship!,
        gender: _gender,
        dateOfBirth:
            _dateOfBirth?.toIso8601String().split('T').first,
        size: _size,
        height: heightText.isEmpty
            ? null
            : double.tryParse(heightText),
        weight: weightText.isEmpty
            ? null
            : double.tryParse(weightText),
        photoUrl: existingProfile.photoUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updatedProfile.profileName} updated successfully',
          ),
        ),
      );

      context.pop(true);
    } else {
      // =====================================================
      // ADD NEW TRY-ON PROFILE
      // =====================================================

      final profile =
          await TryOnProfileService.createProfile(
        profileName: _nameController.text.trim(),
        relationship: _relationship!,
        gender: _gender,
        dateOfBirth:
            _dateOfBirth?.toIso8601String().split('T').first,
        size: _size,
        height: heightText.isEmpty
            ? null
            : double.tryParse(heightText),
        weight: weightText.isEmpty
            ? null
            : double.tryParse(weightText),
        photoUrl: null,
        isDefault: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${profile.profileName} added successfully',
          ),
        ),
      );

      context.pop(true);
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.profile != null
              ? 'Unable to update profile: $e'
              : 'Unable to add person: $e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F3EA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
         widget.profile == null
      ? 'Save Person'
      : 'Save Changes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Add a person',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create a profile so you can try outfits for them.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              // NAME
              const Text(
                'Name *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // RELATIONSHIP
              const Text(
                'Relationship *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Select relationship'),
                items: const [
                  DropdownMenuItem(
                    value: 'Self',
                    child: Text('Self'),
                  ),
                  DropdownMenuItem(
                    value: 'Mother',
                    child: Text('Mother'),
                  ),
                  DropdownMenuItem(
                    value: 'Father',
                    child: Text('Father'),
                  ),
                  DropdownMenuItem(
                    value: 'Sister',
                    child: Text('Sister'),
                  ),
                  DropdownMenuItem(
                    value: 'Brother',
                    child: Text('Brother'),
                  ),
                  DropdownMenuItem(
                    value: 'Spouse',
                    child: Text('Spouse'),
                  ),
                  DropdownMenuItem(
                    value: 'Child',
                    child: Text('Child'),
                  ),
                  DropdownMenuItem(
                    value: 'Friend',
                    child: Text('Friend'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _relationship = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // GENDER
              const Text(
                'Gender *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Select gender'),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),

             
              const SizedBox(height: 20),

const Text(
  'Date of Birth *',
  style: TextStyle(
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 8),

_dateOfBirthField(),

              
              
              const SizedBox(height: 20),

              // SIZE
              const Text(
                'Clothing Size *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _size,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Select size'),
                items: const [
                  DropdownMenuItem(
                    value: 'XS',
                    child: Text('XS'),
                  ),
                  DropdownMenuItem(
                    value: 'S',
                    child: Text('S'),
                  ),
                  DropdownMenuItem(
                    value: 'M',
                    child: Text('M'),
                  ),
                  DropdownMenuItem(
                    value: 'L',
                    child: Text('L'),
                  ),
                  DropdownMenuItem(
                    value: 'XL',
                    child: Text('XL'),
                  ),
                  DropdownMenuItem(
                    value: 'XXL',
                    child: Text('XXL'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _size = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // OPTIONAL HEIGHT
              const Text(
                'Height (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter height',
                  suffixText: 'cm',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // OPTIONAL WEIGHT
              const Text(
                'Weight (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter weight',
                  suffixText: 'kg',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _savePerson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
  widget.profile != null
      ? 'Save Changes'
      : 'Save Person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateOfBirthField() {
  return InkWell(
    onTap: () async {
      final now = DateTime.now();

      final picked = await showDatePicker(
        context: context,
        initialDate: _dateOfBirth ??
            DateTime(
              now.year - 25,
              now.month,
              now.day,
            ),
        firstDate: DateTime(1900),
        lastDate: now,
      );

      if (picked != null) {
        setState(() {
          _dateOfBirth = picked;
        });
      }
    },
    child: InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      child: Text(
        _dateOfBirth == null
            ? 'Select date of birth'
            : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
              '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
              '${_dateOfBirth!.year}',
        style: TextStyle(
          color: _dateOfBirth == null
              ? Colors.black54
              : Colors.black,
        ),
      ),
    ),
  );
}

}