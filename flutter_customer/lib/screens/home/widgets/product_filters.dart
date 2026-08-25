enum SortOption {
  recent, // What's New
  priceLowToHigh,
  priceHighToLow,
  popularity,
  discount,
  customerRating,
}

class ProductFilters {
  // Main category:
  // men / women / kids / beauty / all
  final String? category;

  // Sub category:
  // shirt / saree / pant / t shirts / ...
  final String? subCategory;

  final double? minPrice;
  final double? maxPrice;
  final SortOption sortBy;

  const ProductFilters({
    this.category,
    this.subCategory,
    this.minPrice,
    this.maxPrice,
    this.sortBy = SortOption.recent,
  });

  bool get isDefault =>
      (category == null || category!.toLowerCase() == 'all') &&
      subCategory == null &&
      minPrice == null &&
      maxPrice == null &&
      sortBy == SortOption.recent;

  ProductFilters copyWith({
    String? category,
    String? subCategory,
    double? minPrice,
    double? maxPrice,
    SortOption? sortBy,

    bool clearCategory = false,
    bool clearSubCategory = false,
    bool clearPrice = false,
  }) {
    return ProductFilters(
      category: clearCategory
          ? null
          : (category ?? this.category),

      subCategory: clearSubCategory
          ? null
          : (subCategory ?? this.subCategory),

      minPrice: clearPrice
          ? null
          : (minPrice ?? this.minPrice),

      maxPrice: clearPrice
          ? null
          : (maxPrice ?? this.maxPrice),

      sortBy: sortBy ?? this.sortBy,
    );
  }

  static String sortLabel(SortOption s) {
    switch (s) {
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';

      case SortOption.priceHighToLow:
        return 'Price: High to Low';

      case SortOption.popularity:
        return 'Popularity';

      case SortOption.discount:
        return 'Discount';

      case SortOption.customerRating:
        return 'Customer Rating';

      case SortOption.recent:
        return "What's New";
    }
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    // Main category
    // "all" backend-ku send panna thevai illa.
    if (category != null &&
        category!.trim().isNotEmpty &&
        category!.toLowerCase() != 'all') {
      params['category'] = category!.toLowerCase();
    }

    // Sub category
    if (subCategory != null &&
        subCategory!.trim().isNotEmpty) {
      params['subCategory'] = subCategory!.trim();
    }

    // Price
    if (minPrice != null) {
      params['minPrice'] = minPrice!.toStringAsFixed(0);
    }

    if (maxPrice != null) {
      params['maxPrice'] = maxPrice!.toStringAsFixed(0);
    }

    // Sorting
    switch (sortBy) {
      case SortOption.priceLowToHigh:
        params['sortBy'] = 'price_asc';
        break;

      case SortOption.priceHighToLow:
        params['sortBy'] = 'price_desc';
        break;

      case SortOption.popularity:
        params['sortBy'] = 'popularity';
        break;

      case SortOption.discount:
        params['sortBy'] = 'discount';
        break;

      case SortOption.customerRating:
        params['sortBy'] = 'rating';
        break;

      case SortOption.recent:
        // Backend default
        break;
    }

    return params;
  }
}