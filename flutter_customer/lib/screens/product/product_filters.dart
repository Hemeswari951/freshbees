import 'package:flutter/material.dart';
import '../../models/product_model.dart';

// ===========================================================================
// 1. DATA MODELS & ENUMS
// ===========================================================================

class FilterDataOptions {
  static const List<String> categories = [
    'Price Range',
    'Size',
    'Color',
    'Discount',
    'Rating',
  ];

  // 'Discount' and 'Rating' are threshold pickers — only one makes sense
  // at a time ("above 30%" already covers "above 10%"), so they behave
  // like radio buttons instead of checkboxes.
  static const Set<String> singleSelectGroups = {'Discount', 'Rating'};

  static const List<String> discountOptions = [
    'Above 10%',
    'Above 20%',
    'Above 30%',
    'Above 40%',
    'Above 50%',
  ];

  static const List<String> ratingOptions = [
    '4.0★ & above',
    '3.0★ & above',
    '2.0★ & above',
  ];

  /// One small icon per left-nav category — purely cosmetic, gives the
  /// desktop panel a bit more visual identity than plain text rows.
  static const Map<String, IconData> categoryIcons = {
    'Price Range': Icons.sell_outlined,
    'Size': Icons.straighten_outlined,
    'Color': Icons.palette_outlined,
    'Discount': Icons.percent_rounded,
    'Rating': Icons.star_outline_rounded,
  };

  /// Best-effort color swatch for a color name coming from the backend.
  /// Falls back to grey if the name isn't recognized — this only affects
  /// the little preview circle, it never gates which colors are
  /// selectable. Selectable colors come entirely from the DB now (see
  /// ProductListScreen -> ProductService.getFilterOptions()).
  static const Map<String, Color> _knownColorSwatches = {
    'black': Colors.black,
    'white': Colors.white,
    'red': Colors.red,
    'blue': Colors.blue,
    'navy': Color(0xFF000080),
    'sky blue': Color(0xFF87CEEB),
    'green': Colors.green,
    'yellow': Colors.yellow,
    'pink': Colors.pink,
    'purple': Colors.purple,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'brown': Colors.brown,
    'orange': Colors.orange,
    'gold': Color(0xFFFFD700),
    'maroon': Color(0xFF800000),
    'beige': Color(0xFFF5F5DC),
    'cream': Color(0xFFFFFDD0),
    'olive': Color(0xFF808000),
    'mustard': Color(0xFFFFDB58),
  };

  static Color swatchFor(String colorName) =>
      _knownColorSwatches[colorName.trim().toLowerCase()] ?? Colors.grey;
}

/// Pulls the leading number out of a label like 'Above 30%' or
/// '4.0★ & above' -> 30.0 / 4.0. Used for both query params and the
/// actual product matching logic, so the two never drift apart.
double? extractLeadingNumber(String label) {
  final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(label);
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

String filterGroupToParamKey(String groupLabel) {
  final cleaned = groupLabel
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return cleaned;
}

class ProductFilters {
  static const RangeValues fullPriceRange = RangeValues(0, 5000);

  final RangeValues priceRange;
  final Map<String, Set<String>> selectedFilters;

  const ProductFilters({
    this.priceRange = fullPriceRange,
    this.selectedFilters = const {},
  });

  bool get hasPriceFilter =>
      priceRange.start > fullPriceRange.start ||
      priceRange.end < fullPriceRange.end;

  int get activeCount =>
      selectedFilters.values.fold(0, (sum, set) => sum + set.length);

  List<MapEntry<String, String>> get flattenedSelections {
    final result = <MapEntry<String, String>>[];
    selectedFilters.forEach((group, values) {
      for (final value in values) {
        result.add(MapEntry(group, value));
      }
    });
    return result;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (hasPriceFilter) {
      params['min_price'] = priceRange.start.round().toString();
      params['max_price'] = priceRange.end.round().toString();
    }

    selectedFilters.forEach((group, values) {
      if (values.isEmpty) return;
      if (group == 'Discount' || group == 'Rating') {
        final n = extractLeadingNumber(values.first);
        if (n != null) params[filterGroupToParamKey(group)] = n.toString();
      } else {
        params[filterGroupToParamKey(group)] = values.join(',');
      }
    });

    return params;
  }

  ProductFilters copyWith({
    RangeValues? priceRange,
    Map<String, Set<String>>? selectedFilters,
  }) {
    return ProductFilters(
      priceRange: priceRange ?? this.priceRange,
      selectedFilters: selectedFilters ?? this.selectedFilters,
    );
  }

  /// Case-insensitive, whitespace-trimmed matching — DB values like
  /// 'Navy' / 'Sky Blue' / 'XL' aren't guaranteed to match a selection
  /// exactly on case/spacing, so both sides are normalized here.
  bool matches(ProductModel product) {
    if (product.price < priceRange.start || product.price > priceRange.end) {
      return false;
    }

    final sizeSel = selectedFilters['Size'];
    if (sizeSel != null && sizeSel.isNotEmpty) {
      final productSizes =
          product.sizes.map((s) => s.trim().toLowerCase()).toSet();
      final wanted = sizeSel.map((s) => s.trim().toLowerCase());
      if (!wanted.any(productSizes.contains)) return false;
    }

    final colorSel = selectedFilters['Color'];
    if (colorSel != null && colorSel.isNotEmpty) {
      final productColors =
          product.colors.map((c) => c.trim().toLowerCase()).toSet();
      final wanted = colorSel.map((c) => c.trim().toLowerCase());
      if (!wanted.any(productColors.contains)) return false;
    }

    final discountSel = selectedFilters['Discount'];
    if (discountSel != null && discountSel.isNotEmpty) {
      final threshold = extractLeadingNumber(discountSel.first) ?? 0;
      if (product.discountPercent < threshold) return false;
    }

    final ratingSel = selectedFilters['Rating'];
    if (ratingSel != null && ratingSel.isNotEmpty) {
      final threshold = extractLeadingNumber(ratingSel.first) ?? 0;
      if (product.rating < threshold) return false;
    }

    return true;
  }

  /// Value equality (not identity) so the FilterPanel can tell whether
  /// an incoming `initialFilters` from the parent actually represents a
  /// *different* selection than what it already has in its local draft,
  /// vs. just being a freshly-constructed instance carrying the same
  /// values (which happens on almost every parent rebuild).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductFilters) return false;
    if (priceRange != other.priceRange) return false;
    if (selectedFilters.length != other.selectedFilters.length) return false;
    for (final entry in selectedFilters.entries) {
      final otherSet = other.selectedFilters[entry.key];
      if (otherSet == null || otherSet.length != entry.value.length) {
        return false;
      }
      if (!entry.value.every(otherSet.contains)) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var h = priceRange.hashCode;
    final keys = selectedFilters.keys.toList()..sort();
    for (final k in keys) {
      final values = selectedFilters[k]!.toList()..sort();
      h = Object.hash(h, k, Object.hashAll(values));
    }
    return h;
  }
}

/// Bundle passed to the mobile /filter route via go_router's `extra`.
/// `availableSizes`/`availableColors` come from
/// ProductService.getFilterOptions() (backend-driven) — see
/// ProductListScreen — NOT a hardcoded list.
class FilterPageArgs {
  final ProductFilters filters;
  final List<ProductModel> allProducts;
  final List<String> availableSizes;
  final List<String> availableColors;

  const FilterPageArgs({
    required this.filters,
    required this.allProducts,
    this.availableSizes = const [],
    this.availableColors = const [],
  });
}

// ===========================================================================
// 2. MAIN FILTER PANEL WIDGET
// ===========================================================================

class ThiraaCompleteFilterPanel extends StatefulWidget {
  final ProductFilters? initialFilters;
  final List<ProductModel> allProducts;

  /// Backend-driven — the actual sizes/colors present across visible
  /// products right now.
  final List<String> availableSizes;
  final List<String> availableColors;

  final ValueChanged<ProductFilters>? onApply;

  /// When true (desktop sidebar usage):
  ///  - every checkbox/radio toggle calls [onApply] immediately, so the
  ///    product grid updates live without any explicit "Apply" step.
  ///  - the bottom Cancel / Show-Products bar is hidden entirely, since
  ///    there's nothing left to "apply" or "cancel" — every change is
  ///    already live.
  /// When false (mobile full-page usage, default): behavior is
  /// unchanged — user edits filters freely and only Cancel/Apply
  /// commits or discards the result via Navigator.pop.
  final bool isDesktop;

  const ThiraaCompleteFilterPanel({
    super.key,
    this.initialFilters,
    this.allProducts = const [],
    this.availableSizes = const [],
    this.availableColors = const [],
    this.onApply,
    this.isDesktop = false,
  });

  @override
  State<ThiraaCompleteFilterPanel> createState() =>
      _ThiraaCompleteFilterPanelState();
}

class _ThiraaCompleteFilterPanelState extends State<ThiraaCompleteFilterPanel> {
  late RangeValues _priceRange;
  late Map<String, Set<String>> _selectedFilters;
  int _selectedCategoryIndex = 0;

  static const Color primaryGold = Color(0xFF9E6B27);
  static const Color primaryGoldSoft = Color(0xFFF3E7D6);
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color borderCol = Color(0xFFE5DCD3);

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.initialFilters ?? const ProductFilters());
  }

  /// Keeps this widget in sync whenever the PARENT hands it a different
  /// filter value than what it currently holds — e.g. the "Clear
  /// filters" link shown on the empty-results state resets
  /// ProductListScreen's `_filters` to defaults, which flows back down
  /// here as a new `initialFilters`. Without this, the panel's own
  /// internal `_selectedFilters` would keep showing the old ticks even
  /// though the grid outside had already gone back to "all products".
  ///
  /// Comparing against the CURRENT local draft (not the previous
  /// `oldWidget.initialFilters`) means a rebuild triggered by the
  /// panel's own edit (onApply -> parent setState -> new widget config
  /// with the *same* value) never stomps on what the user is doing,
  /// since `incoming == current` in that case and nothing happens.
  @override
  void didUpdateWidget(covariant ThiraaCompleteFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.initialFilters ?? const ProductFilters();
    final current = ProductFilters(
      priceRange: _priceRange,
      selectedFilters: _selectedFilters,
    );
    if (incoming != current) {
      _syncFrom(incoming);
    }
  }

  void _syncFrom(ProductFilters filters) {
    _priceRange = filters.priceRange;
    _selectedFilters = {
      for (final entry in filters.selectedFilters.entries)
        entry.key: Set<String>.from(entry.value),
    };
  }

  List<String> get _currentLeftNav => FilterDataOptions.categories;
  String get _currentGroupKey => _currentLeftNav[_selectedCategoryIndex];

  bool _isSelected(String groupKey, String item) =>
      (_selectedFilters[groupKey] ?? const {}).contains(item);

  /// Desktop-only: pushes the current draft filters straight to the
  /// parent (ProductListScreen -> _applyDesktopFilters) so the grid on
  /// the left re-filters immediately, with no Apply button needed.
  void _applyIfDesktop() {
    if (!widget.isDesktop) return;
    widget.onApply?.call(
      ProductFilters(priceRange: _priceRange, selectedFilters: _selectedFilters),
    );
  }

  void _toggleSelection(String groupKey, String item) {
    setState(() {
      final current = Set<String>.from(_selectedFilters[groupKey] ?? {});
      if (current.contains(item)) {
        current.remove(item);
      } else {
        current.add(item);
      }
      if (current.isEmpty) {
        _selectedFilters = {..._selectedFilters}..remove(groupKey);
      } else {
        _selectedFilters = {..._selectedFilters, groupKey: current};
      }
    });
    _applyIfDesktop();
  }

  void _selectSingle(String groupKey, String item) {
    setState(() {
      final current = _selectedFilters[groupKey] ?? const {};
      if (current.contains(item)) {
        _selectedFilters = {..._selectedFilters}..remove(groupKey);
      } else {
        _selectedFilters = {..._selectedFilters, groupKey: {item}};
      }
    });
    _applyIfDesktop();
  }

  void _removeSelection(String groupKey, String item) =>
      _toggleSelection(groupKey, item);

  /// Clears just ONE group's selections (Size only, Color only, etc.)
  /// without touching any other filter — used by the per-section
  /// "Clear" link shown at the top of the right-hand panel.
  void _clearGroup(String groupKey) {
    if ((_selectedFilters[groupKey] ?? const {}).isEmpty) return;
    setState(() {
      _selectedFilters = {..._selectedFilters}..remove(groupKey);
    });
    _applyIfDesktop();
  }

  void _clearPriceRange() {
    if (!ProductFilters(priceRange: _priceRange).hasPriceFilter) return;
    setState(() => _priceRange = ProductFilters.fullPriceRange);
    _applyIfDesktop();
  }

  /// Live count of how many of widget.allProducts match the filters
  /// AS CURRENTLY BEING EDITED (not yet applied on mobile; already
  /// applied on desktop since every change pushes to the parent too).
  int get _liveMatchCount {
    final draft = ProductFilters(
      priceRange: _priceRange,
      selectedFilters: _selectedFilters,
    );
    return widget.allProducts.where(draft.matches).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.allProducts.length;
    final matched = _liveMatchCount;

    return Scaffold(
      backgroundColor: Colors.white,
      // No AppBar — no back / close icons. On mobile, Cancel at the
      // bottom is the way out without applying. On desktop there's no
      // bottom bar at all — every toggle is already live.
      body: Column(
        children: [
          _buildHeader(total, matched),
          if (_selectedFilters.isNotEmpty) _buildSelectionsStrip(),
          const Divider(height: 1, color: borderCol),
          Expanded(
            child: Row(
              children: [
                _buildLeftNav(),
                const VerticalDivider(width: 1, color: borderCol),
                Expanded(child: _buildRightSelectionArea()),
              ],
            ),
          ),
          // Desktop: no Cancel/Show-Products bar — every toggle above is
          // already pushed live to the parent via _applyIfDesktop().
          // Mobile: keep the original commit/discard bar.
          if (!widget.isDesktop) _buildCommitBar(total, matched),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------

  Widget _buildHeader(int total, int matched) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: const BoxDecoration(
        color: lightBg,
        border: Border(bottom: BorderSide(color: borderCol)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryGoldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, size: 18, color: primaryGold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  total > 0 ? '$matched of $total products' : 'Refine your search',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilters = {};
                _priceRange = ProductFilters.fullPriceRange;
              });
              _applyIfDesktop();
            },
            icon: const Icon(Icons.refresh_rounded, size: 14, color: primaryGold),
            label: const Text(
              'Reset All',
              style: TextStyle(
                  color: primaryGold, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: borderCol),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionsStrip() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in ProductFilters(
              selectedFilters: _selectedFilters,
            ).flattenedSelections)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryGoldSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryGold)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => _removeSelection(entry.key, entry.value),
                      child: const Icon(Icons.close_rounded,
                          size: 12, color: primaryGold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LEFT NAV
  // ---------------------------------------------------------------------

  Widget _buildLeftNav() {
    return Container(
      width: 140,
      color: lightBg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: _currentLeftNav.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final groupKey = _currentLeftNav[index];
          final groupCount = _selectedFilters[groupKey]?.length ?? 0;
          final icon = FilterDataOptions.categoryIcons[groupKey];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Material(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedCategoryIndex = index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: primaryGold.withOpacity(0.35))
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            size: 15,
                            color: isSelected ? primaryGold : Colors.black45),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          groupKey,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? primaryGold : Colors.black87,
                          ),
                        ),
                      ),
                      if (groupCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$groupCount',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // COMMIT BAR (mobile only)
  // ---------------------------------------------------------------------

  Widget _buildCommitBar(int total, int matched) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderCol)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.maybePop(context),
              child: const Text('CANCEL',
                  style: TextStyle(
                      color: primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final result = ProductFilters(
                  priceRange: _priceRange,
                  selectedFilters: _selectedFilters,
                );
                widget.onApply?.call(result);
                Navigator.maybePop(context, result);
              },
              child: Text(
                total > 0 ? 'SHOW $matched PRODUCTS' : 'APPLY FILTERS',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RIGHT PANEL — per-section header (with its own Clear) + content
  // ---------------------------------------------------------------------

  /// Every section in the right pane gets the same header shape: an
  /// icon + label on the left, and — only when that specific group has
  /// an active selection — a "Clear" link on the right that resets
  /// JUST that group, leaving every other filter untouched.
  Widget _sectionHeader(String label, {required VoidCallback? onClear}) {
    final icon = FilterDataOptions.categoryIcons[label];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: primaryGold),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: Colors.black87,
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Text(
                'Clear',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryGold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightSelectionArea() {
    switch (_currentGroupKey) {
      case 'Price Range':
        final hasPriceFilter =
            ProductFilters(priceRange: _priceRange).hasPriceFilter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Price Range',
                onClear: hasPriceFilter ? _clearPriceRange : null),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 5000,
                    activeColor: primaryGold,
                    onChanged: (val) => setState(() => _priceRange = val),
                    // Apply on release, not on every drag frame — avoids
                    // re-filtering the whole grid dozens of times a
                    // second while the thumb is being dragged.
                    onChangeEnd: (val) {
                      setState(() => _priceRange = val);
                      _applyIfDesktop();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${_priceRange.start.round()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('₹${_priceRange.end.round()}+',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case 'Size':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Size',
                onClear: (_selectedFilters['Size'] ?? const {}).isNotEmpty
                    ? () => _clearGroup('Size')
                    : null),
            Expanded(
              child: widget.availableSizes.isEmpty
                  ? const Center(
                      child: Text('No sizes available',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  : _buildGridList('Size', widget.availableSizes),
            ),
          ],
        );
      case 'Color':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Color',
                onClear: (_selectedFilters['Color'] ?? const {}).isNotEmpty
                    ? () => _clearGroup('Color')
                    : null),
            Expanded(
              child: widget.availableColors.isEmpty
                  ? const Center(
                      child: Text('No colors available',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  : _buildColorList('Color', widget.availableColors),
            ),
          ],
        );
      case 'Discount':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Discount',
                onClear: (_selectedFilters['Discount'] ?? const {}).isNotEmpty
                    ? () => _clearGroup('Discount')
                    : null),
            Expanded(
              child: _buildRadioList(
                  'Discount', FilterDataOptions.discountOptions),
            ),
          ],
        );
      case 'Rating':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Rating',
                onClear: (_selectedFilters['Rating'] ?? const {}).isNotEmpty
                    ? () => _clearGroup('Rating')
                    : null),
            Expanded(
              child: _buildRadioList('Rating', FilterDataOptions.ratingOptions),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildColorList(String groupKey, List<String> colorNames) {
    return ListView.builder(
      itemCount: colorNames.length,
      itemBuilder: (context, index) {
        final colorName = colorNames[index];
        final swatch = FilterDataOptions.swatchFor(colorName);
        final isSelected = _isSelected(groupKey, colorName);
        return ListTile(
          dense: true,
          onTap: () => _toggleSelection(groupKey, colorName),
          leading: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(
                color: swatch == Colors.white ? Colors.black38 : Colors.transparent,
              ),
            ),
          ),
          title: Text(colorName, style: const TextStyle(fontSize: 12)),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: primaryGold, size: 18)
              : const Icon(Icons.circle_outlined, color: Colors.black26, size: 18),
        );
      },
    );
  }

  Widget _buildGridList(String groupKey, List<String> list) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _isSelected(groupKey, item);
        return InkWell(
          onTap: () => _toggleSelection(groupKey, item),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? primaryGoldSoft : Colors.white,
              border: Border.all(color: isSelected ? primaryGold : borderCol, width: isSelected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 14, color: isSelected ? primaryGold : Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryGold : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioList(String groupKey, List<String> list) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _isSelected(groupKey, item);
        return RadioListTile<bool>(
          dense: true,
          title: Text(item, style: const TextStyle(fontSize: 12)),
          value: true,
          groupValue: isSelected ? true : null,
          activeColor: primaryGold,
          onChanged: (_) => _selectSingle(groupKey, item),
        );
      },
    );
  }
}

typedef FilterPanel = ThiraaCompleteFilterPanel;
typedef FilterPage = ThiraaCompleteFilterPanel;