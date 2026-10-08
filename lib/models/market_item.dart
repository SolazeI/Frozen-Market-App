import 'delivery_area.dart';
import 'product.dart';
import 'psgc_location.dart';
import 'shop.dart';

/// A product as shown to a customer: the product, its shop, and the delivery
/// area (if any) that covers the customer's selected location.
class MarketItem {
  const MarketItem({required this.product, required this.shop, this.area});

  final Product product;
  final Shop shop;
  final DeliveryArea? area; // null = seller does not deliver here

  bool get delivers => area != null;
  double? get shippingFee => area?.shippingFee;

  /// "Local" = the seller is in the same city as the customer.
  bool isLocalTo(PsgcLocation loc) =>
      loc.hasCity && shop.location.cityCode == loc.cityCode;

  /// Rule 1/3: orderable only if available, in stock AND seller delivers here.
  bool get canOrder => product.isOrderable && delivers;
}
