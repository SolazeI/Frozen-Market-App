import 'delivery_area.dart';
import 'product.dart';
import 'shop.dart';

/// One cart row. Only ids + quantity + selection are stored; price, stock,
/// shop and delivery fee are always read fresh so they can't go stale.
/// [name] is a snapshot used only if the product is later deleted.
class CartLine {
  const CartLine({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.quantity,
    this.selected = true,
  });

  final String productId;
  final String shopId;
  final String name;
  final int quantity;
  final bool selected;

  CartLine copyWith({int? quantity, bool? selected}) => CartLine(
        productId: productId,
        shopId: shopId,
        name: name,
        quantity: quantity ?? this.quantity,
        selected: selected ?? this.selected,
      );
}

/// Why a cart line cannot be checked out right now.
enum CartIssue { unavailable, outOfStock, insufficientStock, notDelivered }

class CartEntry {
  const CartEntry({required this.line, required this.product, this.issue});

  final CartLine line;
  final Product? product; // null = deleted
  final CartIssue? issue;

  String get name => product?.name ?? line.name;
  double get unitPrice => product?.price ?? 0;
  double get lineTotal => unitPrice * line.quantity;

  String? get issueMessage => switch (issue) {
        null => null,
        CartIssue.unavailable => 'No longer available',
        CartIssue.outOfStock => 'Out of stock',
        CartIssue.insufficientStock => 'Only ${product?.stock ?? 0} left',
        CartIssue.notDelivered => "Seller doesn't deliver to your location",
      };
}

/// All cart rows from one seller. Shipping is charged once per seller, using
/// the delivery area that covers the customer's selected location.
class CartGroup {
  const CartGroup({
    required this.shopId,
    required this.entries,
    this.shop,
    this.area,
  });

  final String shopId;
  final Shop? shop;
  final DeliveryArea? area; // null = seller does not deliver here
  final List<CartEntry> entries;

  String get shopName => shop?.shopName ?? 'Seller';
  bool get delivers => area != null;

  List<CartEntry> get selectedEntries =>
      entries.where((e) => e.line.selected).toList();
  bool get allSelected => entries.every((e) => e.line.selected);

  double get subtotal =>
      selectedEntries.fold(0.0, (sum, e) => sum + e.lineTotal);

  /// Only charged when something from this seller is selected.
  double get shipping =>
      (selectedEntries.isEmpty || area == null) ? 0 : area!.shippingFee;
}

class CartView {
  const CartView(this.groups);
  static const empty = CartView([]);

  final List<CartGroup> groups;

  Iterable<CartEntry> get _selected => groups.expand((g) => g.selectedEntries);

  int get selectedCount => _selected.length;
  int get selectedSellerCount =>
      groups.where((g) => g.selectedEntries.isNotEmpty).length;
  bool get allSelected =>
      groups.isNotEmpty && groups.every((g) => g.allSelected);

  double get subtotal => groups.fold(0.0, (s, g) => s + g.subtotal);
  double get shipping => groups.fold(0.0, (s, g) => s + g.shipping);
  double get total => subtotal + shipping;

  bool get hasProblems => _selected.any((e) => e.issue != null);
  bool get canCheckout => selectedCount > 0 && !hasProblems;

  String? get blockerMessage {
    if (selectedCount == 0) return 'Select items to check out.';
    if (hasProblems) return 'Fix the highlighted items to continue.';
    return null;
  }
}
