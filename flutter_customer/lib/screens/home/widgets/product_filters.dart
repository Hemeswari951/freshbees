enum SortOption {
  recent,          // What's New
  priceLowToHigh,
  priceHighToLow,
  popularity,
  discount,
  customerRating,
}
 
class ProductFilters {
  final String? category; // 'saree', 'pant', 'shirt', 't shirts', 'kids'
  final String? gender;   // 'men' / 'women' / 'all' — set by the tab, not user
  final double? minPrice;
  final double? maxPrice;
  final SortOption sortBy;
 
  const ProductFilters({
    this.category,
    this.gender,
    this.minPrice,
    this.maxPrice,
    this.sortBy = SortOption.recent,
  });
 
  bool get isDefault =>
      category == null &&
      minPrice == null &&
      maxPrice == null &&
      sortBy == SortOption.recent;
 
  ProductFilters copyWith({
    String? category,
    String? gender,
    double? minPrice,
    double? maxPrice,
    SortOption? sortBy,
    bool clearCategory = false,
    bool clearPrice = false,
  }) {
    return ProductFilters(
      category: clearCategory ? null : (category ?? this.category),
      gender: gender ?? this.gender,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
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
    if (gender != null && gender!.toLowerCase() != 'all') {
      params['gender'] = gender!.toLowerCase();
    }
    if (category != null) params['category'] = category!;
    if (minPrice != null) params['minPrice'] = minPrice!.toStringAsFixed(0);
    if (maxPrice != null) params['maxPrice'] = maxPrice!.toStringAsFixed(0);
 
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
        break; // backend default
    }
    return params;
  }
}
 