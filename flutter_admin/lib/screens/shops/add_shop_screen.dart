import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/t_colors.dart';
import '../../services/shop_service.dart';

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

  // ── Step 1 ──
  final _shopNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  // String? _selectedCategoryId;
  // String? _selectedCategoryName;
  // Selected Categories
final List<int> _selectedCategoryIds = [];

// Select All checkbox
bool _selectAllCategories = false;
  XFile? _logoFile;
  XFile? _bannerFile;
  final _picker = ImagePicker();

  // ── Step 2 ──
  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ── Step 3 ──
  final _accountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  // ── Step 4 ──
  final _commissionCtrl = TextEditingController(text: '10');
  bool _activateImmediately = true;
  bool _sendWelcomeEmail = true;
  bool _allowProductUploads = true;
  bool _enablePayoutRequests = false;

  // Categories — id must match your categories table
  // Replace category_id values with actual seeded IDs from your DB
  static const List<Map<String, String>> _categories = [
    
    {'id': '1', 'name': 'Men'},
    {'id': '2', 'name': 'Women'},
    {'id': '3', 'name': 'Kids'},
    {'id': '4', 'name': 'Beauty'},
  ];

  final List<String> _stepLabels = ['Basic', 'Owner', 'Bank', 'Settings'];

  // ── Validation ────────────────────────────────────────────────────────────
  String? _validateStep() {
    switch (_step) {
      case 0:
        if (_shopNameCtrl.text.trim().isEmpty) return 'Shop name is required';
        if (_descCtrl.text.trim().isEmpty) return 'Description is required';
        if (_selectedCategoryIds.isEmpty) {
  return 'Please select at least one category';
}
        if (_addressCtrl.text.trim().isEmpty) return 'Address is required';
        if (_cityCtrl.text.trim().isEmpty) return 'City is required';
        if (_pincodeCtrl.text.trim().isEmpty) return 'Pincode is required';
        return null;
      case 1:
        if (_ownerNameCtrl.text.trim().isEmpty) return 'Owner name is required';
        if (_emailCtrl.text.trim().isEmpty) return 'Email is required';
        if (!_emailCtrl.text.contains('@')) return 'Enter a valid email';
        if (_phoneCtrl.text.trim().isEmpty) return 'Phone is required';
        if (_phoneCtrl.text.length < 10) return 'Enter a valid phone number';
        return null;
      case 2:
        if (_accountCtrl.text.trim().isEmpty) {
          return 'Account number is required';
        }
        if (_bankNameCtrl.text.trim().isEmpty) return 'Bank name is required';
        if (_ifscCtrl.text.trim().isEmpty) return 'IFSC code is required';
        return null;
      case 3:
        if (_commissionCtrl.text.trim().isEmpty) {
          return 'Commission rate is required';
        }
        return null;
    }
    return null;
  }

  void _next() {
    final error = _validateStep();
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _showError(String msg) {
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

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final error = _validateStep();
    if (error != null) {
      _showError(error);
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
        gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        // Step 4
        commissionRate: _commissionCtrl.text.trim(),
        activateImmediately: _activateImmediately,
        sendWelcomeEmail: _sendWelcomeEmail,
        allowProductUploads: _allowProductUploads,
        enablePayoutRequests: _enablePayoutRequests,
      );

      if (!mounted) return;
      _showSuccess('Shop created successfully!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop(true); // true = refresh ShopsScreen
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }




  @override
  void dispose() {
    for (final c in [
      _shopNameCtrl,
      _descCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
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

  // ─── Root build ───────────────────────────────────────────────────────────
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

  // ─── Stepper header ───────────────────────────────────────────────────────
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
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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

          // Title
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

          // Stepper
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

  // ─── Step router ──────────────────────────────────────────────────────────
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

  // ─── Step 1: Basic ────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      children: [
        _card(
          icon: Icons.storefront_outlined,
          title: 'Shop details',
          children: [
            _label('Shop name', required: true),
            _inputField(_shopNameCtrl, hint: "Ravi's Fashion Store"),
            const SizedBox(height: 14),
            _label('Description', required: true),
            _textArea(
              _descCtrl,
              hint: 'Traditional & ethnic wear for the whole family...',
            ),
            const SizedBox(height: 14),
            _label('Category', required: true),
            _categoryDropdown(),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          icon: Icons.location_on_outlined,
          title: 'Location',
          children: [
            _label('Address', required: true),
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
                      _label('City', required: true),
                      _inputField(_cityCtrl, hint: 'Chennai'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('State'),
                      _inputField(_stateCtrl, hint: 'Tamil Nadu'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Pincode', required: true),
                      _inputField(
                        _pincodeCtrl,
                        hint: '600001',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    if (f != null) setState(() => _logoFile = f);
                  },
                  onRemove: () => setState(() => _logoFile = null),
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
                    if (f != null) setState(() => _bannerFile = f);
                  },
                  onRemove: () => setState(() => _bannerFile = null),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 2: Owner ────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return _card(
      icon: Icons.person_outline,
      title: 'Owner details',
      children: [
        _label('Owner name', required: true),
        _inputField(_ownerNameCtrl, hint: 'Ravi Kumar'),
        const SizedBox(height: 14),
        _label('Email', required: true),
        _inputField(
          _emailCtrl,
          hint: 'owner@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 4),
        // Info note about welcome email
        Row(
          children: [
            const Icon(Icons.info_outline, size: 12, color: TColors.brownLight),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'A temporary password will be sent to this email',
                style: TextStyle(fontSize: 11, color: TColors.brownLight),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Phone', required: true),
        _inputField(
          _phoneCtrl,
          hint: '9876543210',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  // ─── Step 3: Bank ─────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return _card(
      icon: Icons.account_balance_outlined,
      title: 'Bank details',
      children: [
        _label('Account number', required: true),
        _inputField(
          _accountCtrl,
          hint: '0123456789',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        _label('Bank name', required: true),
        _inputField(_bankNameCtrl, hint: 'State Bank of India'),
        const SizedBox(height: 14),
        _label('IFSC code', required: true),
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

  // ─── Step 4: Settings ─────────────────────────────────────────────────────
  Widget _buildStep4() {
    return _card(
      icon: Icons.settings_outlined,
      title: 'Settings',
      children: [
        _label('Commission rate (%)', required: true),
        _commissionField(),
        const SizedBox(height: 8),
        _toggleRow(
          'Activate shop immediately',
          'Shop will be visible to customers right away',
          _activateImmediately,
          (v) => setState(() => _activateImmediately = v),
        ),
        _divider(),
        _toggleRow(
          'Send welcome email to owner',
          'Sends login credentials to the owner\'s email',
          _sendWelcomeEmail,
          (v) => setState(() => _sendWelcomeEmail = v),
        ),
        _divider(),
        _toggleRow(
          'Allow product uploads',
          'Owner can add and manage their own products',
          _allowProductUploads,
          (v) => setState(() => _allowProductUploads = v),
        ),
        _divider(),
        _toggleRow(
          'Enable payout requests',
          'Owner can request withdrawal of earnings',
          _enablePayoutRequests,
          (v) => setState(() => _enablePayoutRequests = v),
        ),
      ],
    );
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
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

  // ─── Category dropdown ────────────────────────────────────────────────────
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

        //---------------------------------------
        // Select All
        //---------------------------------------

        CheckboxListTile(
          value: _selectAllCategories,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text("Select All"),
          onChanged: (value) {

            setState(() {

              _selectAllCategories = value!;

              _selectedCategoryIds.clear();

              if (_selectAllCategories) {

                for (final category in _categories) {

                  _selectedCategoryIds.add(
                    int.parse(category["id"]!),
                  );

                }

              }

            });

          },
        ),

        const Divider(),

        //---------------------------------------
        // Category List
        //---------------------------------------

        ..._categories.map((category) {

          final id = int.parse(category["id"]!);

          return CheckboxListTile(

            dense: true,

            controlAffinity:
                ListTileControlAffinity.leading,

            contentPadding: EdgeInsets.zero,

            value: _selectedCategoryIds.contains(id),

            title: Text(category["name"]!),

            onChanged: (value) {

              setState(() {

                if (value == true) {

                  _selectedCategoryIds.add(id);

                } else {

                  _selectedCategoryIds.remove(id);

                }

                _selectAllCategories =
                    _selectedCategoryIds.length ==
                    _categories.length;

              });

            },

          );

        }),

      ],
    ),
  );
}

  // ─── Shared widgets ───────────────────────────────────────────────────────
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

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TColors.black,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(fontSize: 12, color: Color(0xFFCC2222)),
            ),
        ],
      ),
    );
  }

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
                    Icon(
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
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: TColors.black.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                          child: const Text(
                            'Change',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: TColors.white,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _commissionField() {
    return TextField(
      controller: _commissionCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 13, color: TColors.black),
      decoration: InputDecoration(
        suffixText: '% of each order goes to THIRAA',
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
            //activeThumbColor: TColors.white,
            activeTrackColor: const Color(0xFF22AA6F),
            inactiveThumbColor: TColors.white,
            inactiveTrackColor: TColors.border,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: TColors.border, height: 1);
}
