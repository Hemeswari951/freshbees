import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thiraa/widgets/app_colors.dart';
import '../../services/auth_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final String identifier;
  final String password;
  final String? redirectRoute;

  const UserDetailsScreen({
    super.key,
    required this.identifier,
    required this.password,
    this.redirectRoute,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String _gender = 'Other';
  DateTime? _dob;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _handleCreateAccount() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      _showSnackBar("Please enter your first name", isError: true);
      return;
    }

    if (_dob == null) {
      _showSnackBar("Please select your date of birth", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.register(
      identifier: widget.identifier,
      password: widget.password,
      firstName: firstName,
      lastName: lastName.isNotEmpty ? lastName : 'User',
      gender: _gender,
      dob: _dob!.toIso8601String().split('T').first, // YYYY-MM-DD
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginIdentifier', widget.identifier);
      await prefs.setString('userName', '$firstName $lastName'.trim());
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.go(widget.redirectRoute ?? '/home');
    } else {
      _showSnackBar(response.message, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Your Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'First Name',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.accentBrown,
                    ),
                    filled: true,
                    fillColor: AppColors.white.withOpacity(0.95),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Last Name (optional)',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.accentBrown,
                    ),
                    filled: true,
                    fillColor: AppColors.white.withOpacity(0.95),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white.withOpacity(0.95),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'Other'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Date of Birth',
                      prefixIcon: const Icon(
                        Icons.cake_outlined,
                        color: AppColors.accentBrown,
                      ),
                      filled: true,
                      fillColor: AppColors.white.withOpacity(0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Select Date'
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.white,
                          )
                        : const Text(
                            'Create Account',
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
      ),
    );
  }
}
