import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState
    extends State<PersonalDetailsScreen> {

  ProfileModel? _profile;

  bool _loading = true;
  bool _saving = false;
  bool _isEditing = true;

  String? _errorMessage;

  bool get _isEmailLocked {
  return _profile?.email != null &&
      _profile!.email!.trim().isNotEmpty;
}

bool get _isPhoneLocked {
  return _profile?.phone != null &&
      _profile!.phone!.trim().isNotEmpty;
}

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final profile =
          await ProfileService.getProfile();

      if (!mounted) return;

      _profile = profile;

      _firstNameController.text =
          profile.firstName;

      _lastNameController.text =
          profile.lastName;

      _emailController.text =
          profile.email ?? '';

      _phoneController.text =
          profile.phone ?? '';

      _cityController.text =
          profile.city ?? '';

      _stateController.text =
          profile.state ?? '';

      _gender =
          profile.gender;

      if (profile.dateOfBirth != null &&
          profile.dateOfBirth!.isNotEmpty) {
        _dateOfBirth =
            DateTime.tryParse(profile.dateOfBirth!);
      }

      setState(() {
        _loading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDateOfBirth() async {
    if (!_isEditing) return;

    final now = DateTime.now();

    final initialDate =
        _dateOfBirth ??
        DateTime(
          now.year - 18,
          now.month,
          now.day,
        );

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formattedDate() {
    if (_dateOfBirth == null) {
      return 'Select date of birth';
    }

    final day =
        _dateOfBirth!.day.toString().padLeft(2, '0');

    final month =
        _dateOfBirth!.month.toString().padLeft(2, '0');

    final year =
        _dateOfBirth!.year.toString();

    return '$day-$month-$year';
  }

  String? _dateForApi() {
    if (_dateOfBirth == null) {
      return null;
    }

    final year =
        _dateOfBirth!.year.toString().padLeft(4, '0');

    final month =
        _dateOfBirth!.month.toString().padLeft(2, '0');

    final day =
        _dateOfBirth!.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_saving) return;

    if (_firstNameController.text.trim().isEmpty) {
      _showMessage('First name is required');
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showMessage('Last name is required');
      return;
    }

    try {
      setState(() {
        _saving = true;
      });

      final updatedProfile =
          await ProfileService.updateProfile(
        firstName:
            _firstNameController.text.trim(),

        lastName:
            _lastNameController.text.trim(),

        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),

        phone: _phoneController.text.trim().isEmpty
    ? null
    : _phoneController.text.trim(),

        gender:
            _gender,

        city:
            _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),

        state:
            _stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim(),

        dateOfBirth:
            _dateForApi(),
      );

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
         _dateOfBirth =
      updatedProfile.dateOfBirth != null &&
              updatedProfile.dateOfBirth!.isNotEmpty
          ? DateTime.tryParse(
              updatedProfile.dateOfBirth!,
            )
          : null;

        _saving = false;
        _isEditing = false;
      });

      _showMessage(
        'Personal details updated successfully',
      );

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // CANCEL EDIT
  // ============================================================

  void _cancelEdit() {
    if (_profile == null) return;

    setState(() {
      _firstNameController.text =
          _profile!.firstName;

      _lastNameController.text =
          _profile!.lastName;

      _emailController.text =
          _profile!.email ?? '';

      _cityController.text =
          _profile!.city ?? '';

      _stateController.text =
          _profile!.state ?? '';

      _gender =
          _profile!.gender;

      _dateOfBirth =
          _profile!.dateOfBirth != null
              ? DateTime.tryParse(
                  _profile!.dateOfBirth!,
                )
              : null;

      _isEditing = false;
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F4EE),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F4EE),

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Personal Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        centerTitle: true,

      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.black54,
              ),

              const SizedBox(height: 12),

              const Text(
                'Unable to load personal details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [

        ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ==================================================
            // PROFILE HEADER
            // ==================================================

            _profileHeader(),

            const SizedBox(height: 28),

            // ==================================================
            // BASIC DETAILS
            // ==================================================

            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            _buildTextField(
              label: 'First Name',
              controller:
                  _firstNameController,
              enabled: _isEditing,
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            _buildTextField(
              label: 'Last Name',
              controller:
                  _lastNameController,
              enabled: _isEditing,
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            _buildTextField(
  label: 'Email',
  controller: _emailController,
  enabled: _isEditing && !_isEmailLocked,
  keyboardType: TextInputType.emailAddress,
  icon: Icons.email_outlined,
  suffixIcon: _isEmailLocked
      ? const Icon(
          Icons.lock_outline,
          size: 18,
          color: Colors.black45,
        )
      : null,
),
            const SizedBox(height: 14),

            // ==================================================
            // PHONE - READ ONLY
            // ==================================================

            _buildTextField(
  label: 'Mobile Number',
  controller: _phoneController,
  enabled: _isEditing && !_isPhoneLocked,
  keyboardType: TextInputType.phone,
  icon: Icons.phone_outlined,
  suffixIcon: _isPhoneLocked
      ? const Icon(
          Icons.lock_outline,
          size: 18,
          color: Colors.black45,
        )
      : null,
),
            const SizedBox(height: 14),

            // ==================================================
            // GENDER
            // ==================================================

            _buildGenderField(),

            const SizedBox(height: 14),

            // ==================================================
            // DOB
            // ==================================================

            _buildDateField(),

            const SizedBox(height: 28),

            // ==================================================
            // LOCATION
            // ==================================================

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            _buildTextField(
              label: 'City',
              controller:
                  _cityController,
              enabled: _isEditing,
              icon: Icons.location_city_outlined,
            ),

            const SizedBox(height: 14),

            _buildTextField(
              label: 'State',
              controller:
                  _stateController,
              enabled: _isEditing,
              icon: Icons.map_outlined,
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SAVE / CANCEL BUTTONS
            // ==================================================

            if (_isEditing)
              Row(
                children: [

                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving
                              ? null
                              : _cancelEdit,
                      style:
                          OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(0xFFB8A48D),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _saving
                              ? null
                              : _saveProfile,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF8A7356),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 30),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _profileHeader() {
    return Column(
      children: [

        CircleAvatar(
          radius: 42,
          backgroundColor:
              const Color(0xFFE8DFD1),
          child: _profile?.profileImage != null &&
                  _profile!.profileImage!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _profile!.profileImage!,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  Icons.person_outline,
                  size: 42,
                  color: Color(0xFF8A7356),
                ),
        ),

        const SizedBox(height: 12),

        Text(
          _profile?.fullName ?? '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color:
              enabled
                  ? const Color(0xFF8A7356)
                  : Colors.black45,
        ),

        suffixIcon: suffixIcon,

        filled: true,

        fillColor:
            enabled
                ? Colors.white
                : const Color(0xFFF0ECE6),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE2D8CA),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFB8A48D),
            width: 1.5,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE2D8CA),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Widget _buildGenderField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Gender',

        prefixIcon: const Icon(
          Icons.people_outline,
          color: Color(0xFF8A7356),
        ),

        filled: true,

        fillColor:
            _isEditing
                ? Colors.white
                : const Color(0xFFF0ECE6),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE2D8CA),
          ),
        ),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              _gender != null &&
                      [
                        'Male',
                        'Female',
                        'Other',
                      ].contains(_gender)
                  ? _gender
                  : null,

          isExpanded: true,

          hint: const Text(
            'Select gender',
          ),

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

          onChanged:
              _isEditing
                  ? (value) {
                      setState(() {
                        _gender = value;
                      });
                    }
                  : null,
        ),
      ),
    );
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Widget _buildDateField() {
    return InkWell(
      onTap:
          _isEditing
              ? _selectDateOfBirth
              : null,

      borderRadius:
          BorderRadius.circular(14),

      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',

          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF8A7356),
          ),

          suffixIcon:
              _isEditing
                  ? const Icon(
                      Icons.arrow_drop_down,
                    )
                  : null,

          filled: true,

          fillColor:
              _isEditing
                  ? Colors.white
                  : const Color(0xFFF0ECE6),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide:
                const BorderSide(
              color: Color(0xFFE2D8CA),
            ),
          ),
        ),

        child: Text(
          _formattedDate(),

          style: TextStyle(
            fontSize: 16,
            color:
                _dateOfBirth == null
                    ? Colors.black45
                    : Colors.black87,
          ),
        ),
      ),
    );
  }
}