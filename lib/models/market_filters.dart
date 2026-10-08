import 'market_item.dart';
import 'psgc_location.dart';

enum SortOption { newest, priceLow, priceHigh, rating }

extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.newest => 'Newest',
        SortOption.priceLow => 'Price: low to high',
        SortOption.priceHigh => 'Price: high to low',
        SortOption.rating => 'Top rated',
      };
}

/// Search / filter / sort state for the marketplace. Applied on the list of
/// products already limited to the customer's delivery location.
class MarketFilters {
  const MarketFilters({
    this.query = '',
    this.category = 'All',
    this.sort = SortOption.newest,
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.inStockOnly = false,
    this.localOnly = false,
  });

  final String query;
  final String category;
  final SortOption sort;
  final double? minPrice;
  final double? maxPrice;
  final double minRating;
  final bool inStockOnly;
  final bool localOnly;

  /// Number of advanced filters in use (shown on the Filters button).
  int get activeCount =>
      (minPrice != null ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (inStockOnly ? 1 : 0) +
      (localOnly ? 1 : 0);

  MarketFilters copyWith({String? query, String? category, SortOption? sort}) =>
      MarketFilters(
        query: query ?? this.query,
        category: category ?? this.category,
        sort: sort ?? this.sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        inStockOnly: inStockOnly,
        localOnly: localOnly,
      );

  /// Same query/category/sort, with new advanced filters.
  MarketFilters withAdvanced({
    double? minPrice,
    double? maxPrice,
    double minRating = 0,
    bool inStockOnly = false,
    bool localOnly = false,
  }) =>
      MarketFilters(
        query: query,
        category: category,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        inStockOnly: inStockOnly,
        localOnly: localOnly,
      );
}

/// Pure function so it is easy to test.
List<MarketItem> applyFilters(
    List<MarketItem> items, MarketFilters f, PsgcLocation? loc) {
  final q = f.query.trim().toLowerCase();

  final result = items.where((i) {
    final p = i.product;
    if (f.category != 'All' && p.category != f.category) return false;
    if (q.isNotEmpty &&
        !(p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            i.shop.shopName.toLowerCase().contains(q))) {
      return false;
    }
    if (f.minPrice != null && p.price < f.minPrice!) return false;
    if (f.maxPrice != null && p.price > f.maxPrice!) return false;
    if (f.minRating > 0 && p.rating < f.minRating) return false;
    if (f.inStockOnly && !p.inStock) return false;
    if (f.localOnly && (loc == null || !i.isLocalTo(loc))) return false;
    return true;
  }).toList();

  final now = DateTime.now();
  switch (f.sort) {
    case SortOption.priceLow:
      result.sort((a, b) => a.product.price.compareTo(b.product.price));
    case SortOption.priceHigh:
      result.sort((a, b) => b.product.price.compareTo(a.product.price));
    case SortOption.rating:
      result.sort((a, b) => b.product.rating.compareTo(a.product.rating));
    case SortOption.newest:
      result.sort((a, b) => (b.product.createdAt ?? now)
          .compareTo(a.product.createdAt ?? now));
  }
  return result;
}
