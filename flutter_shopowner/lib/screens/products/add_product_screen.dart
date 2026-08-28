import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';
import 'utils/image_enhancer.dart';
import 'utils/camera_capture_screen.dart';
import 'utils/photo_edit_screen.dart';

import 'product_view_screen.dart';

/// Add/Edit Product screen — Flipkart/Amazon seller style, where each color
/// of a product gets its OWN front/back/side/zoom photos and its OWN
/// per-size stock, instead of one shared photo set for the whole product.
///
/// PHOTO PIPELINE (camera + gallery + auto-enhance + manual edit):
///  - Tapping any "add photo" slot (angle tile or 360 spin strip) opens a
///    bottom sheet: "Take photo" (custom live in-app camera, see
///    CameraCaptureScreen) or "Choose from gallery" (image_picker).
///  - Every photo — camera or gallery — is run through
///    ImageEnhancer.enhance() automatically (auto levels, small
///    brightness/contrast/saturation lift, resize+compress) before it's
///    placed in a slot. This is silent; the owner doesn't have to do
///    anything.
///  - A pencil icon appears on any freshly-added LOCAL photo (this
///    session) to open PhotoEditScreen for manual brightness/contrast/
///    saturation/rotate adjustments. Existing server photos (from a
///    previous save) aren't editable in place — replace them with a new
///    photo instead, which goes through the same pipeline.
///
/// SCHEMA ALIGNMENT:
///  - products table: sub_category, fabric, pattern, fit_type, sleeve_type,
///    neck_type, occasion, wash_care, country_of_origin (sku is generated
///    by the backend from shop_id + product_id — no frontend field for it)
///  - product_variants table: optional per-size price/mrp override
///    (Approach 1 — NULL means "use the product's base price")
///  - tags / product_tags tables: free-text tag chips
///  - product_attributes (EAV) table: category-specific extra label/value
///    pairs (Pockets, Closure Type, Heel Height, etc.)
///
/// EDIT MODE: pass an existing `product` map (must contain at least an
/// `id`) to open this same screen as an editor. On open, if `_isEditing`
/// is true, the screen calls `ProductService.getProductDetail(id)` to pull
/// the FULL record (description, mrp, colors incl. photos/sizes, tags,
/// attributes, etc.) and prefills every section — the shallow map handed
/// in from the products list is only used as a placeholder while that
/// request is in flight. Existing photos come back as URLs (not XFile,
/// since they already live on the server) and are shown alongside any new
/// local photo the owner picks to replace them.
///
/// PUBLISH FLOW: on a fresh "Add product", once the product is created on
/// the backend, this screen replaces itself with `ProductViewScreen` for
/// the product that was just published. On "Save changes" (edit mode),
/// this screen pops back to whoever opened it with the updated product.
class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductScreen({super.key, this.product});

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

// Dropdown options matching the fixed "common attribute" columns on the
// `products` table. Keep these in sync with whatever the backend expects.
const List<String> _kFitTypes = [
  'Slim Fit',
  'Regular Fit',
  'Loose Fit',
  'Skinny Fit',
  'Oversized',
];
const List<String> _kSleeveTypes = [
  'Full Sleeve',
  'Half Sleeve',
  '3/4 Sleeve',
  'Sleeveless',
];
const List<String> _kNeckTypes = [
  'Round Neck',
  'V-Neck',
  'Collar',
  'Mandarin Collar',
  'Hooded',
  'Boat Neck',
];
const List<String> _kOccasions = [
  'Casual',
  'Formal',
  'Party',
  'Sports',
  'Ethnic Wear',
  'Daily Wear',
];

// Where a picked photo came from — drives the bottom sheet choice.
enum _PhotoSource { camera, gallery }

// Approach 1: variant price is NULL by default (falls back to the
// product's base price/mrp on the backend via COALESCE). Only filled in
// when this specific size+color combo needs a different price — e.g. a
// premium color, or a bigger size that costs more fabric.
class _SizeRow {
  // Present only for a size row that already exists on the backend
  // (i.e. we're editing it). Null for a brand-new row the owner just
  // added — the update payload uses this to tell "update variant X"
  // apart from "create a new variant".
  int? variantId;
  String size;
  int stock;
  String price; // optional override — empty string means "use base price"
  String mrp; // optional override — empty string means "use base mrp"
  _SizeRow({
    this.variantId,
    this.size = '',
    this.stock = 0,
    this.price = '',
    this.mrp = '',
  });
}

// One row of the product_attributes (EAV) table — category-specific extra
// detail, e.g. label: "Pockets", value: "2". Not shown in `products`
// because most rows would be NULL for it (only relevant to some categories).
class _AttributeRow {
  String label;
  String value;
  _AttributeRow({this.label = '', this.value = ''});
}

class _ColorBlock {
  // Present only when this color already exists on the backend. Null for
  // a color the owner just added in this session.
  int? id;
  final TextEditingController nameCtrl = TextEditingController();
  String? hex;

  // Newly picked local photos (this session) per fixed angle.
  final Map<String, XFile?> images = {for (final a in _kAngles) a: null};
  // Existing photo URLs per fixed angle, as returned by the backend. When
  // an owner picks a new photo for an angle, that new local file takes
  // display priority over the existing URL; the existing URL is kept
  // around so "no change" still submits correctly.
  final Map<String, String?> existingImageUrls = {
    for (final a in _kAngles) a: null,
  };

  // Real 360° turntable sequence — ordered list, NOT the 4 fixed angles
  // above. 8-30 photos shot at even angles while the product spins on a
  // turntable (or the phone circles the product) give a smooth spin.
  // Order matters: the viewer plays them back in exactly this order.
  final List<XFile> spin360 = [];
  // Existing spin photo URLs, in playback order, as returned by the
  // backend. Newly added local photos (spin360 above) are appended after
  // these in the final submitted order.
  final List<String> existingSpin360Urls = [];

  final List<_SizeRow> sizes = [_SizeRow()];
  // When false (default), every size in this color just uses the
  // product's base price/mrp — no per-size price fields shown at all.
  // Flip it on only if this color needs different pricing per size.
  bool useCustomPricing = false;

  bool get hasAnyPhoto =>
      images.values.any((f) => f != null) ||
      existingImageUrls.values.any((u) => u != null) ||
      spin360.isNotEmpty ||
      existingSpin360Urls.isNotEmpty;
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // ── maps to products.sub_category / fabric / pattern / wash_care / country ──
  final _subCategoryCtrl = TextEditingController();
  final _fabricCtrl = TextEditingController();
  final _patternCtrl = TextEditingController();
  final _washCareCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');

  // ── maps to products.fit_type / sleeve_type / neck_type / occasion ─
  String? _fitType;
  String? _sleeveType;
  String? _neckType;
  String? _occasion;

  // ── tags[] → tags + product_tags tables ────────────────────────────
  final _tagInputCtrl = TextEditingController();
  final List<String> _tags = [];

  // ── attributes[] → product_attributes (EAV) table ──────────────────
  final List<_AttributeRow> _attributes = [];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  int? _categoryId;
  int? _brandId;

  final List<_ColorBlock> _colors = [_ColorBlock()];

  bool _loadingMeta = true;
  // Separate from _loadingMeta: in edit mode we also wait on the
  // full-product-detail fetch before the colors/sizes sections are
  // trustworthy. Kept distinct so category/brand dropdowns can render
  // as soon as meta is ready even if the detail fetch is a bit slower.
  bool _loadingDetail = false;
  bool _submitting = false;
  String? _error;

  // Keys of photo slots currently being auto-enhanced (e.g.
  // "front_<blockHash>" or "spin_<blockHash>") — used to show a small
  // spinner over just that slot instead of blocking the whole screen.
  final Set<String> _busyKeys = {};

  // True whenever this screen was opened for an existing product
  // (AddProductScreen(product: someProduct)) instead of a blank add.
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadingDetail = _isEditing;
    _prefillShallowFields();
    _loadMeta();
    if (_isEditing) _loadFullProductDetail();
  }

  // Fills in whatever fields we already know from the "shallow" product
  // map handed in by the products list screen (id, name, category, price,
  // stock, thumbnail, status) so the form isn't blank while the full
  // detail request is still in flight.
  void _prefillShallowFields() {
    if (!_isEditing) return;
    final p = widget.product!;
    _nameCtrl.text = (p['name'] as String?) ?? '';
    if (p['price'] != null) _priceCtrl.text = (p['price'] as num).toString();
    if (p['mrp'] != null) _mrpCtrl.text = (p['mrp'] as num).toString();
  }

  // Fetches the FULL product record — description, mrp, discount, brand,
  // colors (with per-angle photo URLs, 360 photo URLs, and per-size
  // stock/price overrides), material/fit fields, tags, and attributes —
  // and prefills the entire form from it. This is what makes edit mode
  // a real editor instead of only touching name/price/description.
  //
  // ⚠️ BACKEND REQUIREMENT: `ProductService.getProductDetail(id)` needs
  // to hit something like `GET /products/:id` and return a map shaped
  // like the create payload, e.g.:
  // {
  //   "id": 1, "name": ..., "description": ..., "mrp": ..., "price": ...,
  //   "category_id": ..., "brand_id": ...,
  //   "sub_category": ..., "fabric": ..., "pattern": ..., "fit_type": ...,
  //   "sleeve_type": ..., "neck_type": ..., "occasion": ..., "wash_care": ...,
  //   "country_of_origin": ...,
  //   "tags": ["party wear", "summer"],
  //   "attributes": [{"label": "Pockets", "value": "2"}],
  //   "colors": [
  //     {
  //       "id": 11, "color_name": "Brown", "color_hex": "#5C3A2E",
  //       "images": {"front": "https://.../f.jpg", "back": null, ...},
  //       "spin_360_images": ["https://.../1.jpg", ...],
  //       "sizes": [
  //         {"variant_id": 101, "size": "M", "stock": 12,
  //          "price": null, "mrp": null}
  //       ]
  //     }
  //   ]
  // }
  Future<void> _loadFullProductDetail() async {
    final productId = widget.product!['id'] as int?;
    if (productId == null) {
      setState(() => _loadingDetail = false);
      return;
    }
    try {
      final detail = await ProductService.getProductDetail(productId);
      // TEMP DEBUG — remove once prefill is confirmed working. Check this
      // in your console: if `sub_category`/`subCategory`, `fit_type`/
      // `fitType`, `colors[].images`, `colors[].sizes[].stock`/
      // `stockQuantity` etc. aren't present here at all, the backend
      // isn't returning them yet — that's a backend fix, not a frontend
      // one, and no amount of key-matching here will help.
      // ignore: avoid_print
      print('getProductDetail($productId) => $detail');
      if (!mounted) return;
      setState(() {
        _applyDetailToForm(detail);
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _error =
            'Could not load full product details, so some fields (colors, '
            'photos, sizes, tags) may be incomplete: $e';
      });
    }
  }

  // The backend response shape isn't fully pinned down yet, and different
  // endpoints/ORMs commonly return either snake_case (matching DB columns,
  // e.g. `sub_category`) or camelCase (matching the request fields
  // addProduct/updateProduct send, e.g. `subCategory`). Rather than
  // guessing wrong and silently leaving fields blank, every lookup below
  // tries several likely key spellings and uses the first one present.
  //
  // ⚠️ If something is STILL blank after this, print the raw response
  // (see the `print(detail)` in `_loadFullProductDetail`) and check the
  // exact key your backend actually uses for that field, then add it to
  // the relevant list below.
  static dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  void _applyDetailToForm(Map<String, dynamic> p) {
    final name = _pick(p, ['name', 'productName', 'product_name']);
    if (name != null) _nameCtrl.text = name.toString();

    final price = _pick(p, ['price', 'sellingPrice', 'selling_price']);
    if (price != null) _priceCtrl.text = (price as num).toString();

    final mrp = _pick(p, ['mrp']);
    if (mrp != null) _mrpCtrl.text = (mrp as num).toString();

    final description = _pick(p, ['description']);
    if (description != null) _descCtrl.text = description.toString();

    final subCategory = _pick(p, ['sub_category', 'subCategory']);
    if (subCategory != null) _subCategoryCtrl.text = subCategory.toString();

    final fabric = _pick(p, ['fabric']);
    if (fabric != null) _fabricCtrl.text = fabric.toString();

    final pattern = _pick(p, ['pattern']);
    if (pattern != null) _patternCtrl.text = pattern.toString();

    final washCare = _pick(p, ['wash_care', 'washCare']);
    if (washCare != null) _washCareCtrl.text = washCare.toString();

    final country = _pick(p, ['country_of_origin', 'countryOfOrigin']);
    if (country != null) _countryCtrl.text = country.toString();

    final fitType = _pick(p, ['fit_type', 'fitType']);
    if (fitType != null) _fitType = fitType.toString();

    final sleeveType = _pick(p, ['sleeve_type', 'sleeveType']);
    if (sleeveType != null) _sleeveType = sleeveType.toString();

    final neckType = _pick(p, ['neck_type', 'neckType']);
    if (neckType != null) _neckType = neckType.toString();

    final occasion = _pick(p, ['occasion']);
    if (occasion != null) _occasion = occasion.toString();

    final categoryId = _pick(p, ['category_id', 'categoryId']);
    if (categoryId != null) _categoryId = (categoryId as num).toInt();

    final brandId = _pick(p, ['brand_id', 'brandId']);
    if (brandId != null) _brandId = (brandId as num).toInt();

    _tags.clear();
    final tags = _pick(p, ['tags']);
    if (tags is List) {
      _tags.addAll(tags.map((t) => t.toString()));
    }

    _attributes.clear();
    final attributes = _pick(p, ['attributes']);
    if (attributes is List) {
      for (final a in attributes) {
        if (a is Map) {
          final label = _pick(a, ['label', 'attributeLabel']) ?? '';
          final value = _pick(a, ['value', 'attributeValue']) ?? '';
          _attributes.add(
            _AttributeRow(label: label.toString(), value: value.toString()),
          );
        }
      }
    }

    final colors = _pick(p, ['colors']);
    if (colors is List && colors.isNotEmpty) {
      for (final b in _colors) {
        b.nameCtrl.dispose();
      }
      _colors.clear();
      for (final c in colors) {
        if (c is! Map) continue;
        final block = _ColorBlock();

        final colorId = _pick(c, ['id', 'colorId', 'color_id']);
        if (colorId != null) block.id = (colorId as num).toInt();

        final colorName = _pick(c, ['color_name', 'colorName', 'name']);
        block.nameCtrl.text = (colorName ?? '').toString();

        final colorHex = _pick(c, ['color_hex', 'colorHex', 'hex']);
        if (colorHex != null) block.hex = colorHex.toString();

        // Backend shape (product.service.js#toDetail): `images` is a FLAT
        // ARRAY of {id, url, type} — type is one of front/back/side/zoom/
        // '360' — not a map keyed by angle. Also supports the map/flat-key
        // shapes as a fallback in case this ever changes upstream.
        final imagesRaw = _pick(c, ['images', 'photos']);
        if (imagesRaw is List) {
          for (final img in imagesRaw) {
            if (img is! Map) continue;
            final type = _pick(img, ['type', 'image_type'])?.toString();
            final url = _pick(img, ['url', 'image_url'])?.toString();
            if (type == null || url == null || url.isEmpty) continue;
            if (_kAngles.contains(type)) {
              // First image wins for a given angle if there happen to be
              // duplicates; later ones are ignored.
              block.existingImageUrls[type] ??= url;
            } else if (type == '360') {
              block.existingSpin360Urls.add(url);
            }
          }
        } else if (imagesRaw is Map) {
          for (final angle in _kAngles) {
            final v = _pick(imagesRaw, [angle]);
            if (v is String && v.isNotEmpty) block.existingImageUrls[angle] = v;
          }
          final spin = _pick(imagesRaw, ['360', 'spin', 'spin360']);
          if (spin is List) {
            block.existingSpin360Urls.addAll(spin.whereType<String>());
          }
        }

        // Backend key is `variants`, not `sizes`.
        final sizes = _pick(c, ['variants', 'sizes']);
        if (sizes is List && sizes.isNotEmpty) {
          block.sizes.clear();
          for (final s in sizes) {
            if (s is! Map) continue;
            final variantId = _pick(s, ['variant_id', 'variantId', 'id']);
            final size = _pick(s, ['size']);
            final stock = _pick(s, [
              'stock',
              'stockQuantity',
              'stock_quantity',
            ]);
            // Raw override only — NOT effectivePrice/effectiveMrp, which
            // always have a value (COALESCEd against the base price) and
            // would make every size look like it has a custom override.
            final sPrice = _pick(s, ['price']);
            final sMrp = _pick(s, ['mrp']);
            block.sizes.add(
              _SizeRow(
                variantId: variantId == null
                    ? null
                    : (variantId as num).toInt(),
                size: (size ?? '').toString(),
                stock: stock == null ? 0 : (stock as num).toInt(),
                price: sPrice == null ? '' : sPrice.toString(),
                mrp: sMrp == null ? '' : sMrp.toString(),
              ),
            );
          }
          block.useCustomPricing = block.sizes.any(
            (s) => s.price.isNotEmpty || s.mrp.isNotEmpty,
          );
          if (block.sizes.isEmpty) block.sizes.add(_SizeRow());
        }

        _colors.add(block);
      }
    }
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await ProductService.getProductMeta();
      setState(() {
        _categories = meta['categories']!;
        _brands = meta['brands']!;
        _loadingMeta = false;

        // If the full-detail fetch hasn't resolved yet (or failed), fall
        // back to matching the shallow list data's category/brand NAME
        // to an id now that we have the full dropdown lists loaded.
        if (_isEditing && _categoryId == null && _brandId == null) {
          final p = widget.product!;
          if (p['category_id'] != null) {
            _categoryId = p['category_id'] as int;
          } else if (p['category'] != null) {
            final match = _categories.firstWhere(
              (c) => c['category_name'] == p['category'],
              orElse: () => const {},
            );
            _categoryId = match['category_id'] as int?;
          }
          if (p['brand_id'] != null) {
            _brandId = p['brand_id'] as int;
          } else if (p['brand'] != null) {
            final match = _brands.firstWhere(
              (b) => b['brand_name'] == p['brand'],
              orElse: () => const {},
            );
            _brandId = match['brand_id'] as int?;
          }
        }
      });
    } catch (e) {
      setState(() {
        _loadingMeta = false;
        _error = 'Could not load categories/brands: $e';
      });
    }
  }

  // ── Camera vs gallery chooser ───────────────────────────────────────
  //
  // Shows a bottom sheet with "Take photo" (custom live in-app camera —
  // see CameraCaptureScreen) and "Choose from gallery" (image_picker).
  Future<_PhotoSource?> _showPhotoSourceSheet() {
    return showModalBottomSheet<_PhotoSource>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.terracotta,
                ),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(ctx).pop(_PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.terracotta,
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(ctx).pop(_PhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Single angle photo (front/back/side/zoom): pick (camera or gallery),
  // then silently auto-enhance before it lands in the slot.
  Future<void> _pickAngleImage(_ColorBlock block, String angle) async {
    final source = await _showPhotoSourceSheet();
    if (source == null) return;

    XFile? picked;
    if (source == _PhotoSource.camera) {
      final result = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
      );
      if (result != null && result.isNotEmpty) picked = result.first;
    } else {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    }
    if (picked == null) return;

    final key = '${angle}_${block.hashCode}';
    setState(() => _busyKeys.add(key));
    try {
      final enhanced = await ImageEnhancer.enhance(picked);
      if (!mounted) return;
      setState(() {
        block.images[angle] = enhanced;
        // This angle is being REPLACED — clear the old server URL so it's
        // not submitted alongside the new upload. Without this, both the
        // stale existing photo and the freshly picked one got sent on
        // save, and the backend kept both as separate rows — that's what
        // was showing up as an extra/wrong photo on the Product view
        // gallery after editing.
        block.existingImageUrls[angle] = null;
      });
    } finally {
      if (mounted) setState(() => _busyKeys.remove(key));
    }
  }

  // Multi-select — owner picks all their turntable shots in one go (from
  // the gallery), or uses the in-app camera's burst mode to shoot them
  // live in order. Appends to whatever's already there (existing + newly
  // added) so they can add in batches if needed. Every photo goes through
  // the same auto-enhance pass as the angle photos.
  Future<void> _pickSpinImages(_ColorBlock block) async {
    final source = await _showPhotoSourceSheet();
    if (source == null) return;

    List<XFile> picked = [];
    if (source == _PhotoSource.camera) {
      final result = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute(
          builder: (_) => const CameraCaptureScreen(burstMode: true),
        ),
      );
      if (result != null) picked = result;
    } else {
      picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    }
    if (picked.isEmpty) return;

    final key = 'spin_${block.hashCode}';
    setState(() => _busyKeys.add(key));
    try {
      final enhanced = await Future.wait(picked.map(ImageEnhancer.enhance));
      if (!mounted) return;
      setState(() => block.spin360.addAll(enhanced));
    } finally {
      if (mounted) setState(() => _busyKeys.remove(key));
    }
  }

  // Opens the manual editor (brightness/contrast/saturation/rotate) for a
  // freshly-picked LOCAL angle photo. Existing server photos aren't
  // editable in place — pick a new photo for that angle instead.
  Future<void> _editAngleImage(_ColorBlock block, String angle) async {
    final file = block.images[angle];
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final edited = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoEditScreen(initialBytes: bytes, fileName: file.name),
      ),
    );
    if (edited != null) setState(() => block.images[angle] = edited);
  }

  // Same idea for a freshly-picked LOCAL spin photo. `index` is over the
  // combined existing-then-new sequence, same convention as the rest of
  // the spin-photo helpers.
  Future<void> _editSpinImage(_ColorBlock block, int index) async {
    if (index < block.existingSpin360Urls.length) return; // server photo
    final localIndex = index - block.existingSpin360Urls.length;
    final file = block.spin360[localIndex];
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final edited = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoEditScreen(initialBytes: bytes, fileName: file.name),
      ),
    );
    if (edited != null) {
      setState(() => block.spin360[localIndex] = edited);
    }
  }

  // Index is over the combined existing-then-new sequence shown in the UI.
  void _removeSpinImage(_ColorBlock block, int index) => setState(() {
    if (index < block.existingSpin360Urls.length) {
      block.existingSpin360Urls.removeAt(index);
    } else {
      block.spin360.removeAt(index - block.existingSpin360Urls.length);
    }
  });

  void _moveSpinImage(_ColorBlock block, int index, int delta) {
    final combined = <Object>[...block.existingSpin360Urls, ...block.spin360];
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= combined.length) return;
    setState(() {
      final item = combined.removeAt(index);
      combined.insert(newIndex, item);
      block.existingSpin360Urls
        ..clear()
        ..addAll(combined.whereType<String>());
      block.spin360
        ..clear()
        ..addAll(combined.whereType<XFile>());
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

  // ── tag chip helpers ────────────────────────────────────────────
  void _addTag() {
    final raw = _tagInputCtrl.text.trim();
    if (raw.isEmpty) return;
    // allow "party wear, summer" comma-separated paste in one go
    final parts = raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty);
    setState(() {
      for (final t in parts) {
        if (!_tags.any((e) => e.toLowerCase() == t.toLowerCase())) {
          _tags.add(t);
        }
      }
      _tagInputCtrl.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  // ── EAV attribute row helpers ───────────────────────────────────
  void _addAttributeRow() => setState(() => _attributes.add(_AttributeRow()));
  void _removeAttributeRow(int i) => setState(() => _attributes.removeAt(i));

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Same validation for both add and edit now that edit mode has real
    // color/photo/size data loaded via _loadFullProductDetail.
    for (final block in _colors) {
      if (block.nameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Every color needs a name.');
        return;
      }
      if (!block.hasAnyPhoto) {
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
      if (_isEditing) {
        await _submitEdit();
      } else {
        await _submitCreate();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Attribute rows with an empty label are dropped — an owner may add a
  // blank row and never fill it in.
  List<Map<String, String>> get _attributesPayload => _attributes
      .where((a) => a.label.trim().isNotEmpty)
      .map((a) => {'label': a.label.trim(), 'value': a.value.trim()})
      .toList();

  // Shared between add and edit — differs only in whether each color
  // carries an existing `id`/`variantId` and existing photo URLs.
  List<ProductColorInput> _buildColorsPayload() {
    return _colors
        .map(
          (b) => ProductColorInput(
            colorId: b.id,
            colorName: b.nameCtrl.text.trim(),
            colorHex: b.hex,
            images: b.images,
            existingImageUrls: b.existingImageUrls,
            spin360Images: b.spin360,
            existingSpin360Urls: b.existingSpin360Urls,
            sizes: b.sizes
                .where((s) => s.size.trim().isNotEmpty)
                .map(
                  (s) => SizeStockInput(
                    variantId: s.variantId,
                    size: s.size.trim(),
                    stock: s.stock,
                    // blank override fields stay null -> backend falls
                    // back to the product's base price/mrp for this size.
                    price: s.price.trim().isNotEmpty
                        ? double.tryParse(s.price.trim())
                        : null,
                    mrp: s.mrp.trim().isNotEmpty
                        ? double.tryParse(s.mrp.trim())
                        : null,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  // ── ADD flow ─────────────────────────────────────────────────────────
  //
  // Creates the product on the backend, then — instead of just popping
  // back to the products list — REPLACES this screen with the
  // ProductViewScreen for the product that was just published. This is
  // what makes "Review and publish" actually navigate to the product
  // view page instead of silently going nowhere.
  //
  // `pushReplacement(..., result: true)` does two things at once:
  //  1. Swaps this AddProductScreen out for ProductViewScreen in the
  //     navigator stack (so pressing back from the product view goes
  //     straight to the products list, not back to this form).
  //  2. Completes the original `Navigator.push<bool>(...)` future that
  //     ProductsScreen._openAddProduct() is awaiting, with `true` — so
  //     the products list quietly refreshes itself in the background.
  Future<void> _submitCreate() async {
    final created = await ProductService.addProduct(
      productName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: _categoryId,
      brandId: _brandId,
      mrp: _mrpCtrl.text.trim().isNotEmpty
          ? double.tryParse(_mrpCtrl.text.trim())
          : null,
      price: double.parse(_priceCtrl.text.trim()),
      colors: _buildColorsPayload(),
      subCategory: _subCategoryCtrl.text.trim().isNotEmpty
          ? _subCategoryCtrl.text.trim()
          : null,
      fabric: _fabricCtrl.text.trim().isNotEmpty
          ? _fabricCtrl.text.trim()
          : null,
      pattern: _patternCtrl.text.trim().isNotEmpty
          ? _patternCtrl.text.trim()
          : null,
      fitType: _fitType,
      sleeveType: _sleeveType,
      neckType: _neckType,
      occasion: _occasion,
      washCare: _washCareCtrl.text.trim().isNotEmpty
          ? _washCareCtrl.text.trim()
          : null,
      countryOfOrigin: _countryCtrl.text.trim().isNotEmpty
          ? _countryCtrl.text.trim()
          : 'India',
      tags: _tags,
      attributes: _attributesPayload,
    );

    if (!mounted) return;

    // ⚠️ Confirm your backend's create-product response includes an
    // `id` field on the returned product data — this is the same key
    // ProductsScreen/ProductViewScreen already rely on elsewhere.
    final newProductId = created['id'] as int?;

    if (newProductId == null) {
      // Product WAS created, but the response didn't tell us its id —
      // can't open the view screen, so just close this form and let
      // the list refresh instead of navigating nowhere.
      Navigator.of(context).pop(true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProductViewScreen(productId: newProductId),
      ),
      result: true,
    );
  }

  // ── EDIT flow ────────────────────────────────────────────────────────
  //
  // Sends the full form (including colors/photos/sizes now that they're
  // real, prefilled data) to `ProductService.updateProduct(...)`, then
  // pops back with the updated product so the caller (product view /
  // products list) can refresh immediately without a second round trip.
  //
  // ⚠️ BACKEND REQUIREMENT: add `updateProduct(...)` to
  // product_service.dart — same shape as `addProduct`, but sent as a
  // PUT/PATCH to something like `/products/:id`. It should:
  //  - accept the same fields as addProduct plus `productId`
  //  - accept `colorId`/`variantId` on each color/size so the backend
  //    can tell "update this existing row" apart from "insert new row"
  //  - accept `existingImageUrls` / `existingSpin360Urls` so the backend
  //    knows which photos to KEEP as-is vs. which angles got a brand-new
  //    upload (present in `images` / `spin360Images` instead)
  //  - return the updated product in the same shape `getProductDetail`
  //    returns, so this screen can hand it straight back to the caller
  Future<void> _submitEdit() async {
    final productId = widget.product!['id'] as int;

    final updated = await ProductService.updateProduct(
      productId: productId,
      productName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: _categoryId,
      brandId: _brandId,
      mrp: _mrpCtrl.text.trim().isNotEmpty
          ? double.tryParse(_mrpCtrl.text.trim())
          : null,
      price: double.parse(_priceCtrl.text.trim()),
      colors: _buildColorsPayload(),
      subCategory: _subCategoryCtrl.text.trim().isNotEmpty
          ? _subCategoryCtrl.text.trim()
          : null,
      fabric: _fabricCtrl.text.trim().isNotEmpty
          ? _fabricCtrl.text.trim()
          : null,
      pattern: _patternCtrl.text.trim().isNotEmpty
          ? _patternCtrl.text.trim()
          : null,
      fitType: _fitType,
      sleeveType: _sleeveType,
      neckType: _neckType,
      occasion: _occasion,
      washCare: _washCareCtrl.text.trim().isNotEmpty
          ? _washCareCtrl.text.trim()
          : null,
      countryOfOrigin: _countryCtrl.text.trim().isNotEmpty
          ? _countryCtrl.text.trim()
          : 'India',
      tags: _tags,
      attributes: _attributesPayload,
    );

    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _mrpCtrl.dispose();
    _priceCtrl.dispose();
    _subCategoryCtrl.dispose();
    _fabricCtrl.dispose();
    _patternCtrl.dispose();
    _washCareCtrl.dispose();
    _countryCtrl.dispose();
    _tagInputCtrl.dispose();
    for (final b in _colors) {
      b.nameCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingMeta || _loadingDetail;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(
          _isEditing ? 'Edit product' : 'Add product',
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: isLoading
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
                                controller: _subCategoryCtrl,
                                label: 'Sub-category',
                                hint:
                                    'e.g. Casual Shirts, Formal Trousers, '
                                    'Party Wear Dress',
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
                              ];
                              if (narrow) {
                                return Column(
                                  children: [
                                    for (final f in fields) ...[
                                      f,
                                      const SizedBox(height: 14),
                                    ],
                                    _discountPreview(),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      for (
                                        int i = 0;
                                        i < fields.length;
                                        i++
                                      ) ...[
                                        Expanded(child: fields[i]),
                                        if (i != fields.length - 1)
                                          const SizedBox(width: 14),
                                      ],
                                    ],
                                  ),
                                  _discountPreview(),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Material & Fit — maps to the fixed common-attribute
                        // columns on `products` ─────────────────────────────
                        _sectionTitle(
                          'Material & fit',
                          subtitle:
                              'Common details customers filter by — stored '
                              'directly on the product.',
                        ),
                        const SizedBox(height: 10),
                        _SectionPanel(child: _materialAndFitSection()),
                        const SizedBox(height: 24),

                        // Tags — maps to tags + product_tags ──────────────
                        _sectionTitle(
                          'Tags',
                          subtitle:
                              'Keywords for search (e.g. "party wear", '
                              '"summer collection"). Press enter or comma '
                              'to add.',
                        ),
                        const SizedBox(height: 10),
                        _SectionPanel(child: _tagsSection()),
                        const SizedBox(height: 24),

                        // Additional attributes — EAV table ────────────────
                        _sectionTitle(
                          'Additional attributes',
                          subtitle:
                              'Category-specific extra details (e.g. '
                              'Pockets, Closure Type, Heel Height). Optional.',
                        ),
                        const SizedBox(height: 10),
                        _SectionPanel(child: _attributesSection()),
                        const SizedBox(height: 24),

                        _sectionTitle(
                          'Colors',
                          subtitle:
                              'Each color gets its own photos and its own '
                              'size/stock.',
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
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.red.withValues(alpha: 0.3),
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
                        SizedBox(
                          width: double.infinity,
                          child: _AppButton(
                            label: _submitting
                                ? (_isEditing ? 'Saving...' : 'Publishing...')
                                : (_isEditing
                                      ? 'Save changes'
                                      : 'Review and publish'),
                            icon: _submitting ? null : Icons.check,
                            onPressed: _submitting ? null : _submit,
                          ),
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

  // Discount % is NEVER stored or sent to the backend — it's purely
  // derived from MRP and price (discount% = (MRP - price) / MRP * 100).
  // Storing it separately risks it going stale if price changes later
  // without the discount being recalculated. This preview just gives the
  // shop owner a live sense of the discount while typing; the real
  // display on the product page should also calculate it on the fly
  // (see the `variant_effective_price` view in the schema).
  Widget _discountPreview() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mrpCtrl, _priceCtrl]),
      builder: (context, _) {
        final mrp = double.tryParse(_mrpCtrl.text.trim());
        final price = double.tryParse(_priceCtrl.text.trim());
        String text = 'Discount will be calculated automatically.';
        if (mrp != null && price != null && mrp > price && mrp > 0) {
          final pct = ((mrp - price) / mrp * 100).round();
          text = 'Discount: $pct% off (calculated, not stored)';
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        );
      },
    );
  }

  Widget _materialAndFitSection() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 480;
            final fields = [
              _styledField(controller: _fabricCtrl, label: 'Fabric / material'),
              _styledField(controller: _patternCtrl, label: 'Pattern'),
            ];
            if (narrow) {
              return Column(
                children: [fields[0], const SizedBox(height: 14), fields[1]],
              );
            }
            return Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 14),
                Expanded(child: fields[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 480;
            final fitDropdown = _stringDropdown(
              label: 'Fit type',
              value: _fitType,
              options: _kFitTypes,
              onChanged: (v) => setState(() => _fitType = v),
            );
            final sleeveDropdown = _stringDropdown(
              label: 'Sleeve type',
              value: _sleeveType,
              options: _kSleeveTypes,
              onChanged: (v) => setState(() => _sleeveType = v),
            );
            if (narrow) {
              return Column(
                children: [
                  fitDropdown,
                  const SizedBox(height: 14),
                  sleeveDropdown,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: fitDropdown),
                const SizedBox(width: 14),
                Expanded(child: sleeveDropdown),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 480;
            final neckDropdown = _stringDropdown(
              label: 'Neck type',
              value: _neckType,
              options: _kNeckTypes,
              onChanged: (v) => setState(() => _neckType = v),
            );
            final occasionDropdown = _stringDropdown(
              label: 'Occasion',
              value: _occasion,
              options: _kOccasions,
              onChanged: (v) => setState(() => _occasion = v),
            );
            if (narrow) {
              return Column(
                children: [
                  neckDropdown,
                  const SizedBox(height: 14),
                  occasionDropdown,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: neckDropdown),
                const SizedBox(width: 14),
                Expanded(child: occasionDropdown),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _styledField(
          controller: _washCareCtrl,
          label: 'Wash care instructions',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        _styledField(controller: _countryCtrl, label: 'Country of origin'),
      ],
    );
  }

  // ── Tags chip input ─────────────────────────────────────────────
  Widget _tagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagInputCtrl,
                onFieldSubmitted: (_) => _addTag(),
                decoration: _variantDecoration('Type a tag and press enter'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add_circle, color: AppColors.terracotta),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: AppColors.blush,
                    deleteIcon: const Icon(Icons.close, size: 15),
                    onDeleted: () => _removeTag(t),
                    side: const BorderSide(color: AppColors.line),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  // ── EAV attribute editor (label + value rows) ──────────────────
  Widget _attributesSection() {
    return Column(
      children: [
        for (int i = 0; i < _attributes.length; i++) _attributeRow(i),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addAttributeRow,
            icon: const Icon(Icons.add, size: 14, color: AppColors.terracotta),
            label: const Text(
              'Add attribute',
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

  Widget _attributeRow(int index) {
    final row = _attributes[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.label,
              onChanged: (v) => row.label = v,
              decoration: _variantDecoration('Label (e.g. Pockets)'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: row.value,
              onChanged: (v) => row.value = v,
              decoration: _variantDecoration('Value (e.g. 2)'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () => _removeAttributeRow(index),
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
          _styledField(controller: block.nameCtrl, label: 'Color name'),
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
                Expanded(
                  child: _angleTile(block, _kAngles[a], _kAngleLabels[a]),
                ),
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
          _customPricingSwitch(block),
          const SizedBox(height: 8),
          _sizeEditor(block),
        ],
      ),
    );
  }

  // Real 360° turntable photo set — separate from the 4 fixed angle tiles
  // above. Owner multi-selects several photos at once (already shot in
  // order around the product) or adds a few, checks order, adds more.
  // Shows existing (server) photos first, then newly added local ones, as
  // one continuous ordered strip.
  Widget _spin360Section(_ColorBlock block) {
    final totalCount = block.existingSpin360Urls.length + block.spin360.length;
    final busy = _busyKeys.contains('spin_${block.hashCode}');
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
          totalCount == 0
              ? 'For a real spinning-product view: shoot 8-30 photos while '
                    'the item turns a full circle on a turntable (small even '
                    'steps), then add them here IN ORDER. Front/Back/Side above '
                    'are still shown as the main gallery photos.'
              : '$totalCount photo${totalCount == 1 ? '' : 's'} added'
                    '${totalCount < 8 ? ' — add more (8+) for a smooth spin' : ''}.'
                    ' Use ↑↓ to fix the order.',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.inkSoft,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < block.existingSpin360Urls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _spinThumb(
                    block,
                    i,
                    totalCount,
                    networkUrl: block.existingSpin360Urls[i],
                  ),
                ),
              for (int i = 0; i < block.spin360.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _spinThumb(
                    block,
                    block.existingSpin360Urls.length + i,
                    totalCount,
                    file: block.spin360[i],
                  ),
                ),
              GestureDetector(
                onTap: busy ? null : () => _pickSpinImages(block),
                child: Container(
                  width: 74,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: busy
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 18,
                              color: AppColors.inkSoft,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add photos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.inkSoft,
                              ),
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

  // `index`/`totalCount` are over the combined existing-then-new sequence.
  // Pass either `networkUrl` (existing server photo) or `file` (freshly
  // picked local photo), never both. A pencil icon (edit) only shows for
  // local `file` photos — existing server photos aren't editable in place.
  Widget _spinThumb(
    _ColorBlock block,
    int index,
    int totalCount, {
    String? networkUrl,
    XFile? file,
  }) {
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
                  child: networkUrl != null
                      ? Image.network(
                          ProductService.fullImageUrl(networkUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, _) {
                            debugPrint('IMAGE LOAD ERROR: $error');
                            return Container(
                              color: Colors.red,
                            ); // visible, not blush
                          },
                        )
                      : FutureBuilder<Uint8List>(
                          future: file!.readAsBytes(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return Container(color: AppColors.blush);
                            }
                            return Image.memory(snap.data!, fit: BoxFit.cover);
                          },
                        ),
                ),
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (file != null)
                  Positioned(
                    top: 3,
                    left: 3,
                    child: GestureDetector(
                      onTap: () => _editSpinImage(block, index),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 9,
                          color: AppColors.ink,
                        ),
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
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 10,
                        color: AppColors.ink,
                      ),
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
                onTap: index > 0
                    ? () => _moveSpinImage(block, index, -1)
                    : null,
                child: Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: index > 0 ? AppColors.terracotta : AppColors.line,
                ),
              ),
              GestureDetector(
                onTap: index < totalCount - 1
                    ? () => _moveSpinImage(block, index, 1)
                    : null,
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: index < totalCount - 1
                      ? AppColors.terracotta
                      : AppColors.line,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shows the newly picked local photo if there is one, otherwise falls
  // back to the existing server photo for this angle, otherwise the empty
  // "tap to add" placeholder. A pencil (edit) icon appears only for a
  // freshly-picked local photo (`file != null`).
  Widget _angleTile(_ColorBlock block, String angle, String label) {
    final file = block.images[angle];
    final existingUrl = block.existingImageUrls[angle];
    final hasPhoto = file != null || existingUrl != null;
    final busy = _busyKeys.contains('${angle}_${block.hashCode}');

    return GestureDetector(
      onTap: busy ? null : () => _pickAngleImage(block, angle),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : !hasPhoto
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
                    file != null
                        ? FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return Container(color: AppColors.blush);
                              }
                              return Image.memory(
                                snap.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.network(
                            ProductService.fullImageUrl(existingUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, _) {
                              debugPrint('IMAGE LOAD ERROR: $error');
                              return Container(
                                color: Colors.red,
                              ); // visible, not blush
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
                    if (file != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => _editAngleImage(block, angle),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 10,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          block.images[angle] = null;
                          block.existingImageUrls[angle] = null;
                        }),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
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

  // ── Per-color pricing toggle (Approach 1 — variant price override) ──
  // Off (default): every size in this color uses the product's base
  // price/mrp — nothing extra to fill in. On: each size row below gets
  // its own optional price/mrp fields, left blank = still falls back to
  // the base price on the backend (COALESCE(variant.price, product.price)).
  Widget _customPricingSwitch(_ColorBlock block) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Different price for some sizes?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              const Text(
                'e.g. XXL costs more, or this color is a premium pick.',
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        Switch(
          value: block.useCustomPricing,
          activeThumbColor: AppColors.terracotta,
          onChanged: (v) => setState(() => block.useCustomPricing = v),
        ),
      ],
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('size_${row.variantId}_$index'),
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
                  key: ValueKey('stock_${row.variantId}_$index'),
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
          // Only shown when "Different price for some sizes?" is on for
          // this color. Both blank = this size just uses the base price.
          if (block.useCustomPricing) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('mrp_${row.variantId}_$index'),
                    initialValue: row.mrp,
                    onChanged: (v) => row.mrp = v,
                    keyboardType: TextInputType.number,
                    decoration: _variantDecoration(
                      'MRP override (₹) — optional',
                    ),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: TextFormField(
                    key: ValueKey('price_${row.variantId}_$index'),
                    initialValue: row.price,
                    onChanged: (v) => row.price = v,
                    keyboardType: TextInputType.number,
                    decoration: _variantDecoration(
                      'Price override (₹) — optional',
                    ),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),

                const SizedBox(width: 34), // aligns with delete icon above
              ],
            ),
          ],
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
    String? hint,
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
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
            ),
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

  // ── generic string dropdown for fit/sleeve/neck/occasion ───────
  Widget _stringDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
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
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text(
                'Select',
                style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
              ),
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(value: o, child: Text(o)),
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
  }) : padding = const EdgeInsets.all(22);

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
  }) : outline = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: outline ? AppColors.white : AppColors.black,
        foregroundColor: outline ? AppColors.ink : Colors.white,
        side: outline
            ? const BorderSide(color: AppColors.line)
            : BorderSide.none,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
