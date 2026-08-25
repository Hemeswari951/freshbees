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

    final hasPriceFilter = priceRange.start > fullPriceRange.start ||
        priceRange.end < fullPriceRange.end;
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

  const ThiraaCompleteFilterPanel({
    super.key,
    this.initialFilters,
    this.allProducts = const [],
    this.availableSizes = const [],
    this.availableColors = const [],
    this.onApply,
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
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color borderCol = Color(0xFFE5DCD3);

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters ?? const ProductFilters();
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
  }

  void _removeSelection(String groupKey, String item) =>
      _toggleSelection(groupKey, item);

  /// Live count of how many of widget.allProducts match the filters
  /// AS CURRENTLY BEING EDITED (not yet applied).
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
      // No AppBar — no back / close icons. Cancel at the bottom is the
      // way out without applying.
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      total > 0 ? '$matched of $total products' : 'Refine your search',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFilters = {}),
                  icon: const Icon(Icons.refresh, size: 14, color: primaryGold),
                  label: const Text(
                    'Reset All',
                    style: TextStyle(
                        color: primaryGold, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedFilters.isNotEmpty)
            Container(
              width: double.infinity,
              color: lightBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'SELECTIONS: ',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    for (final entry in ProductFilters(
                      selectedFilters: _selectedFilters,
                    ).flattenedSelections)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.value,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeSelection(entry.key, entry.value),
                              child: const Icon(Icons.close, size: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1, color: borderCol),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 135,
                  color: lightBg,
                  child: ListView.builder(
                    itemCount: _currentLeftNav.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      final groupKey = _currentLeftNav[index];
                      final groupCount = _selectedFilters[groupKey]?.length ?? 0;
                      return InkWell(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : lightBg,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? primaryGold : Colors.transparent,
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  groupKey,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? primaryGold : Colors.black87,
                                  ),
                                ),
                              ),
                              if (groupCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: primaryGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$groupCount',
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1, color: borderCol),
                Expanded(child: _buildRightSelectionArea()),
              ],
            ),
          ),
          Container(
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
                        style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 11)),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSelectionArea() {
    switch (_currentGroupKey) {
      case 'Price Range':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PRICE RANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 5000,
                activeColor: primaryGold,
                onChanged: (val) => setState(() => _priceRange = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${_priceRange.start.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('₹${_priceRange.end.round()}+',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      case 'Size':
        if (widget.availableSizes.isEmpty) {
          return const Center(
            child: Text('No sizes available', style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }
        return _buildGridList('Size', widget.availableSizes);
      case 'Color':
        if (widget.availableColors.isEmpty) {
          return const Center(
            child: Text('No colors available', style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }
        return _buildColorList('Color', widget.availableColors);
      case 'Discount':
        return _buildRadioList('Discount', FilterDataOptions.discountOptions);
      case 'Rating':
        return _buildRadioList('Rating', FilterDataOptions.ratingOptions);
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
      padding: const EdgeInsets.all(10),
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
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? lightBg : Colors.white,
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