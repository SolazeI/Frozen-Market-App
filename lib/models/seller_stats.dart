/// Numbers shown on the seller dashboard.
class SellerStats {
  const SellerStats({
    required this.totalProducts,
    required this.pendingOrders,
    required this.totalSales,
    required this.rating,
    required this.totalReviews,
  });

  final int totalProducts;
  final int pendingOrders;
  final double totalSales;
  final double rating;
  final int totalReviews;
}
