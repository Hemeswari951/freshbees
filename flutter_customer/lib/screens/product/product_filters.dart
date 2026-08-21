import 'package:flutter/material.dart';

// ===========================================================================
// MODEL — ProductFilters + static FilterOptions
// ===========================================================================

/// Static filter option lists — hardcoded for now. Move to an API call
/// later without touching ProductFilters or the bottom sheet below.
class FilterOptions {
  static const double minPrice = 0;
  static const double maxPrice = 10000;

  static const List<String> categories = ['Men', 'Women', 'Kids'];

  /// label -> swatch color shown in the bottom sheet.
  static const Map<String, Color> colors = {
    'Red': Color(0xFFE53935),
    'Blue': Color(0xFF1E88E5),
    'Black': Color(0xFF212121),
    'White': Color(0xFFFAFAFA),
    'Green': Color(0xFF43A047),
    'Yellow': Color(0xFFFDD835),
    'Pink': Color(0xFFEC407A),
    'Grey': Color(0xFF9E9E9E),
  };

  /// "30% off or more" style buckets.
  static const List<int> discounts = [10, 20, 30, 50, 70];

  /// "4 stars & above" style buckets.
  static const List<double> ratings = [4, 3, 2];
}

/// Holds the currently-applied filter selection. Immutable — use
/// [copyWith] to change values.
class ProductFilters {
  final RangeValues priceRange;
  final Set<String> colors;
  final Set<String> categories;
  final int? minDiscount;
  final double? minRating;

  const ProductFilters({
    this.priceRange = const RangeValues(FilterOptions.minPrice, FilterOptions.maxPrice),
    this.colors = const {},
    this.categories = const {},
    this.minDiscount,
    this.minRating,
  });

  bool get isDefault =>
      priceRange.start == FilterOptions.minPrice &&
      priceRange.end == FilterOptions.maxPrice &&
      colors.isEmpty &&
      categories.isEmpty &&
      minDiscount == null &&
      minRating == null;

  /// Used to show a count badge on the filter icon.
  int get activeCount {
    var count = 0;
    if (priceRange.start != FilterOptions.minPrice || priceRange.end != FilterOptions.maxPrice) count++;
    if (colors.isNotEmpty) count++;
    if (categories.isNotEmpty) count++;
    if (minDiscount != null) count++;
    if (minRating != null) count++;
    return count;
  }

  ProductFilters copyWith({
    RangeValues? priceRange,
    Set<String>? colors,
    Set<String>? categories,
    int? minDiscount,
    bool clearMinDiscount = false,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return ProductFilters(
      priceRange: priceRange ?? this.priceRange,
      colors: colors ?? this.colors,
      categories: categories ?? this.categories,
      minDiscount: clearMinDiscount ? null : (minDiscount ?? this.minDiscount),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  /// Converts to query params for the product-list API call.
  /// TODO: match these key names to what your backend actually expects.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (priceRange.start != FilterOptions.minPrice) {
      params['minPrice'] = priceRange.start.round().toString();
    }
    if (priceRange.end != FilterOptions.maxPrice) {
      params['maxPrice'] = priceRange.end.round().toString();
    }
    if (colors.isNotEmpty) params['colors'] = colors.join(',');
    if (categories.isNotEmpty) {
      params['categories'] = categories.map((c) => c.toLowerCase()).join(',');
    }
    if (minDiscount != null) params['minDiscount'] = minDiscount.toString();
    if (minRating != null) params['minRating'] = minRating.toString();
    return params;
  }
}

// ===========================================================================
// UI — FilterBottomSheet
// ===========================================================================

/// Opens as a modal bottom sheet, lets the user edit filters, and pops
/// with the new [ProductFilters] when "Apply" is tapped (or `null` if
/// dismissed without applying).
///
/// Usage:
/// ```dart
/// final result = await showModalBottomSheet<ProductFilters>(
///   context: context,
///   isScrollControlled: true,
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (_) => FilterBottomSheet(initialFilters: _filters),
/// );
/// if (result != null) setState(() => _filters = result);
/// ```
class FilterBottomSheet extends StatefulWidget {
  final ProductFilters initialFilters;

  const FilterBottomSheet({super.key, required this.initialFilters});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ProductFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildColorSection(),
                  const SizedBox(height: 24),
                  _buildDiscountSection(),
                  const SizedBox(height: 24),
                  _buildRatingSection(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _draft = const ProductFilters()),
            child: const Text('Clear all'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Price range'),
        RangeSlider(
          values: _draft.priceRange,
          min: FilterOptions.minPrice,
          max: FilterOptions.maxPrice,
          divisions: 20,
          labels: RangeLabels(
            '₹${_draft.priceRange.start.round()}',
            '₹${_draft.priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() => _draft = _draft.copyWith(priceRange: values));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${_draft.priceRange.start.round()}'),
              Text('₹${_draft.priceRange.end.round()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterOptions.categories.map((category) {
            final selected = _draft.categories.contains(category);
            return ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (isSelected) {
                final updated = {..._draft.categories};
                isSelected ? updated.add(category) : updated.remove(category);
                setState(() => _draft = _draft.copyWith(categories: updated));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: FilterOptions.colors.entries.map((entry) {
            final selected = _draft.colors.contains(entry.key);
            return GestureDetector(
              onTap: () {
                final updated = {..._draft.colors};
                selected ? updated.remove(entry.key) : updated.add(entry.key);
                setState(() => _draft = _draft.copyWith(colors: updated));
              },
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.black12,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: entry.value.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(entry.key, style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Discount'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterOptions.discounts.map((discount) {
            final selected = _draft.minDiscount == discount;
            return ChoiceChip(
              label: Text('$discount% off or more'),
              selected: selected,
              onSelected: (isSelected) {
                setState(() {
                  _draft = _draft.copyWith(
                    minDiscount: isSelected ? discount : null,
                    clearMinDiscount: !isSelected,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Rating'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FilterOptions.ratings.map((rating) {
            final selected = _draft.minRating == rating;
            return ChoiceChip(
              avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
              label: Text('${rating.toStringAsFixed(0)}+ & above'),
              selected: selected,
              onSelected: (isSelected) {
                setState(() {
                  _draft = _draft.copyWith(
                    minRating: isSelected ? rating : null,
                    clearMinRating: !isSelected,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, _draft),
            child: Text(
              _draft.activeCount > 0
                  ? 'Apply (${_draft.activeCount})'
                  : 'Apply',
            ),
          ),
        ),
      ),
    );
  }
}