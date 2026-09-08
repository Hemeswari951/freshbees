import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/shop_service.dart';
import '../../widgets/t_colors.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AddShopScreen extends StatelessWidget {
  const AddShopScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AddShopBody();
}

// ─── Stateful wrapper ─────────────────────────────────────────────────────────

class _AddShopBody extends StatefulWidget {
  const _AddShopBody();

  @override
  State<_AddShopBody> createState() => _AddShopBodyState();
}

class _AddShopBodyState extends State<_AddShopBody> {
  int _step = 0;
  bool _isSubmitting = false;

  // ── Step 1 ────────────────────────────────────────────────────────────────

  final _shopNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _locationUrlCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;

  final List<int> _selectedCategoryIds = [];
  bool _selectAllCategories = false;

  XFile? _logoFile;
  XFile? _bannerFile;

  final _picker = ImagePicker();

  // ── Step 2 ────────────────────────────────────────────────────────────────

  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ── Step 3 ────────────────────────────────────────────────────────────────

  final _accountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  // ── Step 4 ────────────────────────────────────────────────────────────────

  final _commissionCtrl = TextEditingController(text: '10');

  bool _activateImmediately = true;
  bool _sendWelcomeEmail = true;
  bool _allowProductUploads = true;
  bool _enablePayoutRequests = false;

  // ── Categories ────────────────────────────────────────────────────────────

  static const List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Men'},
    {'id': '2', 'name': 'Women'},
    {'id': '3', 'name': 'Kids'},
    {'id': '4', 'name': 'Beauty'},
  ];

  final List<String> _stepLabels = ['Basic', 'Owner', 'Bank', 'Settings'];

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION URL → COORDINATES
  // ─────────────────────────────────────────────────────────────────────────

  void _extractCoordinatesFromUrl(String url) {
    if (url.trim().isEmpty) {
      if (_latitude != null || _longitude != null) {
        setState(() {
          _latitude = null;
          _longitude = null;
        });
      }
      return;
    }

    try {
      // Example:
      // https://www.google.com/maps/@13.0826800,80.2707200,15z

      final RegExp regExpAt = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');

      final matchAt = regExpAt.firstMatch(url);

      if (matchAt != null && matchAt.groupCount >= 2) {
        final lat = double.tryParse(matchAt.group(1)!);
        final lng = double.tryParse(matchAt.group(2)!);

        setState(() {
          _latitude = lat;
          _longitude = lng;
        });

        return;
      }

      // Google Maps URL data format:
      // !3d13.0826800!4d80.2707200

      final RegExp regExpData = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)');

      final matchData = regExpData.firstMatch(url);

      if (matchData != null && matchData.groupCount >= 2) {
        final lat = double.tryParse(matchData.group(1)!);
        final lng = double.tryParse(matchData.group(2)!);

        setState(() {
          _latitude = lat;
          _longitude = lng;
        });

        return;
      }

      // No coordinates found.
      if (_latitude != null || _longitude != null) {
        setState(() {
          _latitude = null;
          _longitude = null;
        });
      }
    } catch (_) {
      if (_latitude != null || _longitude != null) {
        setState(() {
          _latitude = null;
          _longitude = null;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────────────

  bool _validateBasicDetails() {
    if (_shopNameCtrl.text.trim().isEmpty) {
      _showError('Shop name is required');
      return false;
    }

    if (_descCtrl.text.trim().isEmpty) {
      _showError('Description is required');
      return false;
    }

    if (_selectedCategoryIds.isEmpty) {
      _showError('Please select at least one category');
      return false;
    }

    if (_addressCtrl.text.trim().isEmpty) {
      _showError('Address is required');
      return false;
    }

    if (_cityCtrl.text.trim().isEmpty) {
      _showError('City is required');
      return false;
    }

    if (_stateCtrl.text.trim().isEmpty) {
      _showError('State is required');
      return false;
    }

    final pincode = _pincodeCtrl.text.trim();

    if (pincode.isEmpty) {
      _showError('Pincode is required');
      return false;
    }

    if (pincode.length != 6) {
      _showError('Pincode must contain exactly 6 digits');
      return false;
    }

    final locationUrl = _locationUrlCtrl.text.trim();

    if (locationUrl.isEmpty) {
      _showError('Google Maps location is required');
      return false;
    }

    if (_latitude == null || _longitude == null) {
      _showError(
        'Please enter a valid Google Maps URL containing location coordinates',
      );
      return false;
    }

    return true;
  }

  bool _validateOwnerDetails() {
    if (_ownerNameCtrl.text.trim().isEmpty) {
      _showError('Owner name is required');
      return false;
    }

    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showError('Owner email is required');
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return false;
    }

    final phone = _phoneCtrl.text.trim();

    if (phone.isEmpty) {
      _showError('Owner phone number is required');
      return false;
    }

    if (phone.length != 10) {
      _showError('Phone number must contain exactly 10 digits');
      return false;
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEXT / BACK
  // ─────────────────────────────────────────────────────────────────────────

  void _next() {
    if (_isSubmitting) return;

    if (_step == 0) {
      if (!_validateBasicDetails()) return;
    }

    if (_step == 1) {
      if (!_validateOwnerDetails()) return;
    }

    if (_step < 3) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_isSubmitting) return;

    if (_step > 0) {
      setState(() => _step--);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SNACKBARS
  // ─────────────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFFA32D2D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting) return;

    // Final validation before API call.
    if (!_validateBasicDetails()) {
      setState(() => _step = 0);
      return;
    }

    if (!_validateOwnerDetails()) {
      setState(() => _step = 1);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ShopService.createShop(
        // Step 1
        shopName: _shopNameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryIds: _selectedCategoryIds,
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),

        locationUrl: _locationUrlCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,

        logoFile: _logoFile,
        bannerFile: _bannerFile,

        // Step 2
        ownerName: _ownerNameCtrl.text.trim(),
        ownerEmail: _emailCtrl.text.trim(),
        ownerPhone: _phoneCtrl.text.trim(),

        // Step 3
        accountNumber: _accountCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
        gstNumber: _gstCtrl.text.trim().isEmpty
            ? null
            : _gstCtrl.text.trim().toUpperCase(),

        // Step 4
        commissionRate: _commissionCtrl.text.trim().isEmpty
            ? '10'
            : _commissionCtrl.text.trim(),
        activateImmediately: _activateImmediately,
        sendWelcomeEmail: _sendWelcomeEmail,
        allowProductUploads: _allowProductUploads,
        enablePayoutRequests: _enablePayoutRequests,
      );

      if (!mounted) return;

      _showSuccess('Shop created successfully!');

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final c in [
      _shopNameCtrl,
      _descCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
      _locationUrlCtrl,
      _ownerNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _accountCtrl,
      _bankNameCtrl,
      _ifscCtrl,
      _gstCtrl,
      _commissionCtrl,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.cream,
      body: Column(
        children: [
          _buildStepperHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEPPER HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepperHeader(BuildContext context) {
    return Container(
      color: TColors.cream,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: TColors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Shop',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TColors.black,
                ),
              ),
              Text(
                'Step ${_step + 1} of 4',
                style: const TextStyle(fontSize: 10, color: TColors.brownLight),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final done = i < _step;
                final active = i == _step;

                return Expanded(
                  child: Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 1,
                            color: i <= _step ? TColors.black : TColors.border,
                          ),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done || active
                                  ? TColors.black
                                  : TColors.white,
                              border: Border.all(
                                color: done || active
                                    ? TColors.black
                                    : TColors.border,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(
                                      Icons.check,
                                      size: 13,
                                      color: TColors.white,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? TColors.white
                                            : TColors.brownLight,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _stepLabels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: active
                                  ? TColors.black
                                  : TColors.brownLight,
                            ),
                          ),
                        ],
                      ),
                      if (i < _stepLabels.length - 1)
                        Expanded(
                          child: Container(
                            height: 1,
                            color: i < _step ? TColors.black : TColors.border,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP CONTENT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — BASIC
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        _card(
          icon: Icons.storefront_outlined,
          title: 'Shop details',
          children: [
            _requiredLabel('Shop name'),
            _inputField(_shopNameCtrl, hint: "Ravi's Fashion Store"),
            const SizedBox(height: 14),

            _requiredLabel('Description'),
            _textArea(_descCtrl, hint: 'Traditional & ethnic wear...'),
            const SizedBox(height: 14),

            _requiredLabel('Category'),
            _categoryDropdown(),
          ],
        ),

        const SizedBox(height: 12),

        _card(
          icon: Icons.location_on_outlined,
          title: 'Location',
          children: [
            _requiredLabel('Address'),
            _inputField(
              _addressCtrl,
              hint: 'Shop / street address',
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('City'),
                      _inputField(_cityCtrl, hint: 'Chennai'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('State'),
                      _inputField(_stateCtrl, hint: 'Tamil Nadu'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Pincode'),
                      _inputField(
                        _pincodeCtrl,
                        hint: '600001',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _requiredLabel('Google Maps URL / Location'),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationUrlCtrl,
                    onChanged: _extractCoordinatesFromUrl,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(fontSize: 13, color: TColors.black),
                    decoration: InputDecoration(
                      hintText: 'Paste maps URL here...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: TColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: TColors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final urlString = _locationUrlCtrl.text.trim();

                    final uri = Uri.parse(
                      urlString.isNotEmpty
                          ? urlString
                          : 'https://maps.google.com',
                    );

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      _showError('Could not launch Map');
                    }
                  },
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: TColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TColors.border),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: TColors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF1D9E75),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Location detected: '
                      '${_latitude!.toStringAsFixed(7)}, '
                      '${_longitude!.toStringAsFixed(7)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1D9E75),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        _card(
          icon: Icons.image_outlined,
          title: 'Upload media',
          children: [
            Row(
              children: [
                _uploadBox(
                  label: 'Shop logo',
                  file: _logoFile,
                  onTap: () async {
                    final f = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );

                    if (f != null) {
                      setState(() => _logoFile = f);
                    }
                  },
                  onRemove: () {
                    setState(() => _logoFile = null);
                  },
                ),
                const SizedBox(width: 12),
                _uploadBox(
                  label: 'Banner image',
                  file: _bannerFile,
                  onTap: () async {
                    final f = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );

                    if (f != null) {
                      setState(() => _bannerFile = f);
                    }
                  },
                  onRemove: () {
                    setState(() => _bannerFile = null);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — OWNER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return _card(
      icon: Icons.person_outline,
      title: 'Owner details',
      children: [
        _requiredLabel('Owner name'),
        _inputField(_ownerNameCtrl, hint: 'Ravi Kumar'),

        const SizedBox(height: 14),

        _requiredLabel('Email'),
        _inputField(
          _emailCtrl,
          hint: 'owner@email.com',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 14),

        _requiredLabel('Phone'),
        _inputField(
          _phoneCtrl,
          hint: '9876543210',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — BANK
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return _card(
      icon: Icons.account_balance_outlined,
      title: 'Bank details',
      children: [
        _label('Account number'),
        _inputField(
          _accountCtrl,
          hint: '0123456789',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        const SizedBox(height: 14),

        _label('Bank name'),
        _inputField(_bankNameCtrl, hint: 'State Bank of India'),

        const SizedBox(height: 14),

        _label('IFSC code'),
        _inputField(
          _ifscCtrl,
          hint: 'SBIN0001234',
          textCapitalization: TextCapitalization.characters,
        ),

        const SizedBox(height: 14),

        _label('GST number'),
        _inputField(
          _gstCtrl,
          hint: 'Optional',
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — SETTINGS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep4() {
    return _card(
      icon: Icons.settings_outlined,
      title: 'Settings',
      children: [
        _label('Commission rate (%)'),
        _commissionField(),

        const SizedBox(height: 8),

        _toggleRow(
          'Activate shop immediately',
          'Visible to customers right away',
          _activateImmediately,
          (v) => setState(() => _activateImmediately = v),
        ),

        _divider(),

        _toggleRow(
          'Send welcome email to owner',
          'Sends login credentials',
          _sendWelcomeEmail,
          (v) => setState(() => _sendWelcomeEmail = v),
        ),

        _divider(),

        _toggleRow(
          'Allow product uploads',
          'Owner can manage products',
          _allowProductUploads,
          (v) => setState(() => _allowProductUploads = v),
        ),

        _divider(),

        _toggleRow(
          'Enable payout requests',
          'Owner can request withdrawal',
          _enablePayoutRequests,
          (v) => setState(() => _enablePayoutRequests = v),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM NAV
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: TColors.white,
        border: Border(top: BorderSide(color: TColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: GestureDetector(
                onTap: _isSubmitting ? null : _back,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: TColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 15, color: TColors.black),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: TColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          Expanded(
            flex: _step > 0 ? 2 : 1,
            child: GestureDetector(
              onTap: _isSubmitting ? null : (_step == 3 ? _submit : _next),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                decoration: BoxDecoration(
                  color: _isSubmitting
                      ? TColors.black.withValues(alpha: 0.5)
                      : TColors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: TColors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _step == 3 ? Icons.check : Icons.arrow_forward,
                            size: 15,
                            color: TColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _step == 3 ? 'Save shop' : 'Continue',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: TColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _selectAllCategories,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Select All', style: TextStyle(fontSize: 13)),
            onChanged: (value) {
              setState(() {
                _selectAllCategories = value ?? false;

                _selectedCategoryIds.clear();

                if (_selectAllCategories) {
                  for (final category in _categories) {
                    _selectedCategoryIds.add(int.parse(category['id']!));
                  }
                }
              });
            },
          ),

          const Divider(),

          ..._categories.map((category) {
            final id = int.parse(category['id']!);

            return CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              value: _selectedCategoryIds.contains(id),
              title: Text(
                category['name']!,
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!_selectedCategoryIds.contains(id)) {
                      _selectedCategoryIds.add(id);
                    }
                  } else {
                    _selectedCategoryIds.remove(id);
                  }

                  _selectAllCategories =
                      _selectedCategoryIds.length == _categories.length;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: TColors.brownLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REQUIRED LABEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _requiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TColors.black,
              ),
            ),
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA32D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TColors.black,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INPUT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _inputField(
    TextEditingController ctrl, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 13, color: TColors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.black, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT AREA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _textArea(TextEditingController ctrl, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 200,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(),
          style: const TextStyle(fontSize: 13, color: TColors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            filled: true,
            fillColor: TColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TColors.black, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Text(
          '${ctrl.text.length}/200',
          style: const TextStyle(fontSize: 10, color: TColors.brownLight),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD BOX
  // ─────────────────────────────────────────────────────────────────────────

  Widget _uploadBox({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: file == null ? onTap : null,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: TColors.cream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: file != null ? TColors.black : TColors.border,
              width: file != null ? 1.5 : 1,
            ),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_outlined,
                      size: 20,
                      color: TColors.brownLight,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TColors.brownLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to upload',
                      style: TextStyle(fontSize: 10, color: TColors.brownLight),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: kIsWeb
                          ? Image.network(file.path, fit: BoxFit.cover)
                          : Image.file(File(file.path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: TColors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: TColors.white,
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

  // ─────────────────────────────────────────────────────────────────────────
  // COMMISSION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _commissionField() {
    return TextField(
      controller: _commissionCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 13, color: TColors.black),
      decoration: InputDecoration(
        suffixText: '% of each order',
        suffixStyle: const TextStyle(fontSize: 11, color: TColors.brownLight),
        filled: true,
        fillColor: TColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TColors.black, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOGGLE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _toggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF22AA6F),
            inactiveThumbColor: TColors.white,
            inactiveTrackColor: TColors.border,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(color: TColors.border, height: 1);
  }
}
