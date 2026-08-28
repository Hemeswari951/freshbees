import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tryon_profile_service.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _relationship;
  String? _gender;
  String? _ageGroup;
  String? _size;

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
      _ageGroup == null ||
      _size == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all required fields'),
      ),
    );
    return;
  }

  try {
    // Convert age group to an age only if your UI
    // currently doesn't have an exact age field.
    int? age;

    switch (_ageGroup) {
      case 'Child':
        age = 10;
        break;
      case 'Teen':
        age = 16;
        break;
      case 'Adult':
        age = 25;
        break;
      case 'Senior':
        age = 60;
        break;
    }

    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final profile = await TryOnProfileService.createProfile(
      profileName: _nameController.text.trim(),
      relationship: _relationship!,
      gender: _gender,
      age: age,
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

    // Return to profile selection.
    context.pop(true);

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to add person: $e',
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
        title: const Text(
          'Add Person',
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
                value: _relationship,
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
                value: _gender,
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

              // AGE GROUP
              const Text(
                'Age Group *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _ageGroup,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Select age group'),
                items: const [
                  DropdownMenuItem(
                    value: 'Child',
                    child: Text('Child'),
                  ),
                  DropdownMenuItem(
                    value: 'Teen',
                    child: Text('Teen'),
                  ),
                  DropdownMenuItem(
                    value: 'Adult',
                    child: Text('Adult'),
                  ),
                  DropdownMenuItem(
                    value: 'Senior',
                    child: Text('Senior'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _ageGroup = value;
                  });
                },
              ),

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
                value: _size,
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
                  child: const Text(
                    'Save Person',
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
}