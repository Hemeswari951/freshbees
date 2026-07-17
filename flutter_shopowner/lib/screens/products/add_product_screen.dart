import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';

/// Add Product screen — Flipkart/Amazon seller style, extended so each color
/// of a product gets its OWN front/back/side/zoom photos and its OWN
/// per-size stock, instead of one shared photo set for the whole product.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

const List<String> _kAngles = ['front', 'back', 'side', 'zoom'];
const List<String> _kAngleLabels = ['Front', 'Back', 'Side', 'Zoom'];

// Preset swatches so a non-technical owner can tap a color instead of typing
// a hex code. "Custom" just means "I typed the name, no swatch chosen".
const Map<String, String> _kColorPresets = {
  'Brown': '#5C3A2E',
  'Black': '#1F1B18',
  'White': '#F5F1E8',
  'Red': '#B23A2E',
  'Blue': '#2E4E8C',
  'Green': '#3E6B4A',
  'Beige': '#D8C6A8',
};

class _SizeRow {
  String size;
  int stock;
  _SizeRow({this.size = '', this.stock = 0});
}

class _ColorBlock {
  final TextEditingController nameCtrl = TextEditingController();
  String? hex;
  final Map<String, XFile?> images = {
    for (final a in _kAngles) a: null,
  };
  // Real 360° turntable sequence — ordered list, NOT the 4 fixed angles
  // above. 8-30 photos shot at even angles while the product spins on a
  // turntable (or the phone circles the product) give a smooth spin.
  // Order matters: the viewer plays them back in exactly this order.
  final List<XFile> spin360 = [];
  final List<_SizeRow> sizes = [_SizeRow()];
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  int? _categoryId;
  int? _brandId;

  final List<_ColorBlock> _colors = [_ColorBlock()];

  bool _loadingMeta = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await ProductService.getProductMeta();
      setState(() {
        _categories = meta['categories']!;
        _brands = meta['brands']!;
        _loadingMeta = false;
      });
    } catch (e) {
      setState(() {
        _loadingMeta = false;
        _error = 'Could not load categories/brands: $e';
      });
    }
  }

  Future<void> _pickAngleImage(_ColorBlock block, String angle) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => block.images[angle] = picked);
  }

  // Multi-select — owner picks all their turntable shots in one go, in
  // the same order they'll play back in the 360 viewer. Appends to
  // whatever's already there so they can add in batches if needed.
  Future<void> _pickSpinImages(_ColorBlock block) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => block.spin360.addAll(picked));
  }

  void _removeSpinImage(_ColorBlock block, int index) =>
      setState(() => block.spin360.removeAt(index));

  void _moveSpinImage(_ColorBlock block, int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= block.spin360.length) return;
    setState(() {
      final item = block.spin360.removeAt(index);
      block.spin360.insert(newIndex, item);
    });
  }

  void _addColor() => setState(() => _colors.add(_ColorBlock()));
  void _removeColor(int i) => setState(() {
    if (_colors.length > 1) _colors.removeAt(i);
  });

  void _addSizeRow(_ColorBlock block) =>
      setState(() => block.sizes.add(_SizeRow()));
  void _removeSizeRow(_ColorBlock block, int i) => setState(() {
    if (block.sizes.length > 1) block.sizes.removeAt(i);
  });

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    for (final block in _colors) {
      if (block.nameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Every color needs a name.');
        return;
      }
      if (block.images.values.every((f) => f == null) &&
          block.spin360.isEmpty) {
        setState(
          () => _error =
              'Color "${block.nameCtrl.text.trim()}" needs at least one photo.',
        );
        return;
      }
      final hasValidSize = block.sizes.any((s) => s.size.trim().isNotEmpty);
      if (!hasValidSize) {
        setState(
          () => _error =
              'Color "${block.nameCtrl.text.trim()}" needs at least one size.',
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final colorsPayload = _colors
          .map(
            (b) => ProductColorInput(
              colorName: b.nameCtrl.text.trim(),
              colorHex: b.hex,
              images: b.images,
              spin360Images: b.spin360,
              sizes: b.sizes
                  .where((s) => s.size.trim().isNotEmpty)
                  .map((s) => SizeStockInput(size: s.size.trim(), stock: s.stock))
                  .toList(),
            ),
          )
          .toList();

      await ProductService.addProduct(
        productName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _categoryId,
        brandId: _brandId,
        mrp: _mrpCtrl.text.trim().isNotEmpty
            ? double.tryParse(_mrpCtrl.text.trim())
            : null,
        price: double.parse(_priceCtrl.text.trim()),
        discountPercent: int.tryParse(_discountCtrl.text.trim()) ?? 0,
        colors: colorsPayload,
      );
      if (mounted) Navigator.of(context).pop(true); // true = "refresh the list"
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _mrpCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    for (final b in _colors) b.nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Add product',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Basic details'),
                        const SizedBox(height: 10),
                        _SectionPanel(
                          child: Column(
                            children: [
                              _styledField(
                                controller: _nameCtrl,
                                label: 'Product name',
                                validator: _requiredValidator,
                              ),
                              const SizedBox(height: 14),
                              _styledField(
                                controller: _descCtrl,
                                label: 'Description',
                                maxLines: 4,
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, c) {
                                  final narrow = c.maxWidth < 480;
                                  final categoryDropdown = _categoryDropdown();
                                  final brandDropdown = _brandDropdown();
                                  if (narrow) {
                                    return Column(
                                      children: [
                                        categoryDropdown,
                                        const SizedBox(height: 14),
                                        brandDropdown,
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: categoryDropdown),
                                      const SizedBox(width: 14),
                                      Expanded(child: brandDropdown),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle('Pricing'),
                        const SizedBox(height: 10),
                        _SectionPanel(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final narrow = c.maxWidth < 480;
                              final fields = [
                                _styledField(
                                  controller: _mrpCtrl,
                                  label: 'MRP (₹)',
                                  keyboardType: TextInputType.number,
                                ),
                                _styledField(
                                  controller: _priceCtrl,
                                  label: 'Selling price (₹)',
                                  keyboardType: TextInputType.number,
                                  validator: _requiredValidator,
                                ),
                                _styledField(
                                  controller: _discountCtrl,
                                  label: 'Discount %',
                                  keyboardType: TextInputType.number,
                                ),
                              ];
                              if (narrow) {
                                return Column(
                                  children: [
                                    for (final f in fields) ...[
                                      f,
                                      const SizedBox(height: 14),
                                    ],
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  for (int i = 0; i < fields.length; i++) ...[
                                    Expanded(child: fields[i]),
                                    if (i != fields.length - 1)
                                      const SizedBox(width: 14),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle(
                          'Colors',
                          subtitle:
                              'Each color gets its own photos and its own size/stock.',
                        ),
                        const SizedBox(height: 10),
                        for (int i = 0; i < _colors.length; i++) ...[
                          _colorBlockPanel(i),
                          const SizedBox(height: 14),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addColor,
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: AppColors.terracotta,
                            ),
                            label: const Text(
                              'Add another color',
                              style: TextStyle(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _AppButton(
                              label: _submitting
                                  ? 'Publishing...'
                                  : 'Review and publish',
                              icon: _submitting ? null : Icons.check,
                              onPressed: _submitting ? null : _submit,
                            ),
                            const SizedBox(width: 12),
                            _AppButton(
                              label: 'Cancel',
                              outline: true,
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Color block: name + swatch, 4 angle photo slots, size/stock rows ────
  Widget _colorBlockPanel(int index) {
    final block = _colors[index];
    return _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Color ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              if (_colors.length > 1)
                IconButton(
                  onPressed: () => _removeColor(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _styledField(
            controller: block.nameCtrl,
            label: 'Color name',
          ),
          const SizedBox(height: 10),
          // Preset swatches — tap to fill both the name field and hex.
          // A non-technical owner never has to type a hex code by hand.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kColorPresets.entries.map((entry) {
              final selected = block.hex == entry.value;
              return GestureDetector(
                onTap: () => setState(() {
                  block.nameCtrl.text = entry.key;
                  block.hex = entry.value;
                }),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(
                      int.parse(entry.value.replaceFirst('#', '0xFF')),
                    ),
                    border: Border.all(
                      color: selected ? AppColors.terracotta : AppColors.line,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            'Photos',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int a = 0; a < _kAngles.length; a++) ...[
                Expanded(child: _angleTile(block, _kAngles[a], _kAngleLabels[a])),
                if (a != _kAngles.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),

          _spin360Section(block),
          const SizedBox(height: 16),

          const Text(
            'Sizes and stock',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          _sizeEditor(block),
        ],
      ),
    );
  }

  // Real 360° turntable photo set — separate from the 4 fixed angle tiles
  // above. Owner multi-selects several photos at once (already shot in
  // order around the product) or adds a few, checks order, adds more.
  Widget _spin360Section(_ColorBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '360° spin photos',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'optional',
                style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          block.spin360.isEmpty
              ? 'For a real spinning-product view: shoot 8-30 photos while '
                  'the item turns a full circle on a turntable (small even '
                  'steps), then add them here IN ORDER. Front/Back/Side above '
                  'are still shown as the main gallery photos.'
              : '${block.spin360.length} photo${block.spin360.length == 1 ? '' : 's'} added'
                  '${block.spin360.length < 8 ? ' — add more (8+) for a smooth spin' : ''}.'
                  ' Use ↑↓ to fix the order.',
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.3),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < block.spin360.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _spinThumb(block, i),
                ),
              GestureDetector(
                onTap: () => _pickSpinImages(block),
                child: Container(
                  width: 74,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.inkSoft),
                      SizedBox(height: 4),
                      Text(
                        'Add photos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spinThumb(_ColorBlock block, int index) {
    final file = block.spin360[index];
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FutureBuilder<Uint8List>(
                    future: file.readAsBytes(),
                    builder: (context, snap) {
                      if (!snap.hasData) return Container(color: AppColors.blush);
                      return Image.memory(snap.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: 3,
                  right: 3,
                  child: GestureDetector(
                    onTap: () => _removeSpinImage(block, index),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 10, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: index > 0 ? () => _moveSpinImage(block, index, -1) : null,
                child: Icon(Icons.chevron_left, size: 16, color: index > 0 ? AppColors.terracotta : AppColors.line),
              ),
              GestureDetector(
                onTap: index < block.spin360.length - 1 ? () => _moveSpinImage(block, index, 1) : null,
                child: Icon(Icons.chevron_right, size: 16, color: index < block.spin360.length - 1 ? AppColors.terracotta : AppColors.line),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _angleTile(_ColorBlock block, String angle, String label) {
    final file = block.images[angle];
    return GestureDetector(
      onTap: () => _pickAngleImage(block, angle),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List>(
                      future: file.readAsBytes(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Container(color: AppColors.blush);
                        }
                        return Image.memory(snap.data!, fit: BoxFit.cover);
                      },
                    ),
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => block.images[angle] = null),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 11,
                            color: AppColors.ink,
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

  Widget _sizeEditor(_ColorBlock block) {
    return Column(
      children: [
        for (int i = 0; i < block.sizes.length; i++) _sizeRow(block, i),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addSizeRow(block),
            icon: const Icon(Icons.add, size: 14, color: AppColors.terracotta),
            label: const Text(
              'Add size',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sizeRow(_ColorBlock block, int index) {
    final row = block.sizes[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.size,
              onChanged: (v) => row.size = v,
              decoration: _variantDecoration('Size (e.g. S, M, L, XL)'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: row.stock == 0 ? '' : row.stock.toString(),
              onChanged: (v) => row.stock = int.tryParse(v) ?? 0,
              keyboardType: TextInputType.number,
              decoration: _variantDecoration('Stock qty'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: block.sizes.length > 1
                ? () => _removeSizeRow(block, index)
                : null,
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.blush,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              hint: const Text(
                'Select',
                style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
              ),
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
              items: items
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e[idKey] as int,
                      child: Text(e[nameKey] as String),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryDropdown() => _dropdown(
    label: 'Category',
    value: _categoryId,
    items: _categories,
    idKey: 'category_id',
    nameKey: 'category_name',
    onChanged: (v) => setState(() => _categoryId = v),
  );

  Widget _brandDropdown() => _dropdown(
    label: 'Brand',
    value: _brandId,
    items: _brands,
    idKey: 'brand_id',
    nameKey: 'brand_name',
    onChanged: (v) => setState(() => _brandId = v),
  );

  InputDecoration _variantDecoration(String hint) => InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
    filled: true,
    fillColor: AppColors.blush,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.terracotta),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Local replacements for what used to come from common_widgets.dart.
// Kept private (_prefixed) since only this file needs them.
// ─────────────────────────────────────────────────────────────

class _SectionPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionPanel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outline;

  const _AppButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: outline ? AppColors.white : AppColors.black,
        foregroundColor: outline ? AppColors.ink : Colors.white,
        side: outline ? const BorderSide(color: AppColors.line) : BorderSide.none,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}