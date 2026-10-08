import 'cart_item.dart';
import 'delivery_area.dart';
import 'product.dart';
import 'shop.dart';

/// "Buy now" skips the cart and checks out one product directly.
class BuyNowItem {
  const BuyNowItem(
      {required this.productId, required this.shopId, required this.quantity});
  final String productId;
  final String shopId;
  final int quantity;

  (String, String, int) get key => (productId, shopId, quantity);
}

/// Live data needed to display a cart.
class CartLookup {
  const CartLookup(
      {required this.products, required this.shops, required this.areas});
  final Map<String, Product> products; // by productId
  final Map<String, Shop> shops; // by shopId
  final Map<String, DeliveryArea?> areas; // by shopId (null = doesn't deliver)
}

class CartLine {
  const CartLine({required this.item, this.product});
  final CartItem item;
  final Product? product; // null = product was deleted

  int get quantity => item.quantity;
  bool get selected => item.selected;
  double get unitPrice => product?.price ?? 0;
  double get total => unitPrice * quantity;

  /// Reason this line blocks checkout, or null if it is fine.
  String? get issue {
    final p = product;
    if (p == null || !p.isAvailable) return 'No longer available';
    if (p.stock <= 0) return 'Out of stock';
    if (quantity > p.stock) return 'Only ${p.stock} left';
    return null;
  }
}

/// One seller's part of the cart. Shipping is per seller and per location.
class CartGroup {
  const CartGroup({required this.shop, required this.area, required this.lines});
  final Shop shop;
  final DeliveryArea? area;
  final List<CartLine> lines;

  bool get delivers => area != null;
  List<CartLine> get selectedLines =>
      lines.where((l) => l.selected).toList();

  double get subtotal => selectedLines.fold(0, (s, l) => s + l.total);
  double get shipping =>
      (selectedLines.isEmpty || area == null) ? 0 : area!.shippingFee;
  double get total => subtotal + shipping;

  bool get blocked =>
      selectedLines.isNotEmpty &&
      (!delivers || selectedLines.any((l) => l.issue != null));
}

class CartView {
  const CartView(this.groups);
  final List<CartGroup> groups;

  static const empty = CartView([]);

  factory CartView.build(List<CartItem> items, CartLookup lookup) {
    final byShop = <String, List<CartLine>>{};
    for (final i in items) {
      byShop
          .putIfAbsent(i.shopId, () => [])
          .add(CartLine(item: i, product: lookup.products[i.productId]));
    }
    return CartView([
      for (final e in byShop.entries)
        CartGroup(
          shop: lookup.shops[e.key] ??
              Shop(
                  shopId: e.key,
                  sellerId: e.key,
                  shopName: 'Unavailable shop'),
          area: lookup.areas[e.key],
          lines: e.value,
        ),
    ]);
  }

  List<CartGroup> get selectedGroups =>
      groups.where((g) => g.selectedLines.isNotEmpty).toList();

  double get subtotal => groups.fold(0, (s, g) => s + g.subtotal);
  double get shipping => groups.fold(0, (s, g) => s + g.shipping);
  double get total => subtotal + shipping;
  int get selectedCount =>
      groups.fold(0, (s, g) => s + g.selectedLines.length);

  /// Something is selected and nothing selected is blocked.
  bool get canCheckout =>
      selectedGroups.isNotEmpty && !groups.any((g) => g.blocked);
}
