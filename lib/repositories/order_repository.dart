import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/firestore_utils.dart';
import '../models/delivery_area.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/product.dart';
import '../models/psgc_location.dart';

class PlaceOrderLine {
  const PlaceOrderLine(this.productId, this.quantity);
  final String productId;
  final int quantity;
}

class PlaceOrderGroup {
  const PlaceOrderGroup(this.shopId, this.lines);
  final String shopId;
  final List<PlaceOrderLine> lines;
}

/// Orders. All stock/shipping decisions are re-checked here against fresh
/// Firestore data inside transactions; the UI numbers are never trusted.
class OrderRepository {
  OrderRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(Collections.orders);
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(Collections.products);
  CollectionReference<Map<String, dynamic>> get _areas =>
      _db.collection(Collections.deliveryAreas);

  List<CustomerOrder> _parse(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map((d) => CustomerOrder.fromMap(d.data())).toList();
    final now = DateTime.now();
    list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return list;
  }

  Stream<List<CustomerOrder>> watchSellerOrders(String sellerId) =>
      _orders.where('sellerId', isEqualTo: sellerId).snapshots().map(_parse);

  Stream<List<CustomerOrder>> watchCustomerOrders(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map(_parse);

  Stream<CustomerOrder?> watchOrder(String orderId) =>
      _orders.doc(orderId).snapshots().map((s) =>
          (s.exists && s.data() != null) ? CustomerOrder.fromMap(s.data()!) : null);

  String _orderNumber(String id) {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'FM-${two(n.year % 100)}${two(n.month)}${two(n.day)}-${id.substring(0, 5).toUpperCase()}';
  }

  // ---------------------------------------------------------------------
  // Checkout: one order per seller, created atomically.
  // Validates: product exists/listed, stock (NOT deducted yet), the seller
  // still delivers to the address, and recomputes shipping from the seller's
  // current delivery area. Inventory is only deducted when the seller accepts.
  // ---------------------------------------------------------------------
  Future<List<CustomerOrder>> placeOrders({
    required String customerId,
    required DeliveryAddress address,
    required PaymentMethod method,
    String? paymentReference,
    required List<PlaceOrderGroup> groups,
    required bool clearCart,
  }) {
    final loc = address.location;
    final cityLevel = PsgcLocation(cityCode: loc.cityCode);

    return _db.runTransaction<List<CustomerOrder>>((tx) async {
      // ---- 1. all reads first ----
      final shopSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final areaSnaps = <String, List<DocumentSnapshot<Map<String, dynamic>>>>{};
      final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final g in groups) {
        shopSnaps[g.shopId] =
            await tx.get(_db.collection(Collections.shops).doc(g.shopId));
        areaSnaps[g.shopId] = [
          // barangay-level area (more specific) and city-level area
          await tx.get(_areas.doc(DeliveryArea.buildId(g.shopId, loc))),
          await tx.get(_areas.doc(DeliveryArea.buildId(g.shopId, cityLevel))),
        ];
        for (final l in g.lines) {
          productSnaps[l.productId] = await tx.get(_products.doc(l.productId));
        }
      }

      // ---- 2. validate + build ----
      final orders = <CustomerOrder>[];
      for (final g in groups) {
        final shop = shopSnaps[g.shopId]!;
        if (!shop.exists) {
          throw const AppException(
              'A seller in your cart is no longer available.');
        }
        final shopData = shop.data()!;
        final shopName = shopData['shopName'] as String? ?? 'Shop';

        DeliveryArea? area;
        for (final s in areaSnaps[g.shopId]!) {
          if (!s.exists) continue;
          final a = DeliveryArea.fromMap(s.data()!);
          if (!a.isActive || !a.covers(loc)) continue;
          if (area == null || (a.isBarangayLevel && !area.isBarangayLevel)) {
            area = a;
          }
        }
        if (area == null) {
          throw AppException('$shopName does not deliver to ${loc.shortLabel}.');
        }

        final items = <OrderItem>[];
        double subtotal = 0;
        for (final l in g.lines) {
          final snap = productSnaps[l.productId]!;
          if (!snap.exists) {
            throw const AppException('A product in your cart no longer exists.');
          }
          final p = Product.fromMap(snap.data()!);
          if (p.shopId != g.shopId) {
            throw const AppException('Invalid item in your cart.');
          }
          if (!p.isAvailable) {
            throw AppException('"${p.name}" is no longer available.');
          }
          if (l.quantity < 1) {
            throw const AppException('Quantity must be at least 1.');
          }
          if (p.stock < l.quantity) {
            throw AppException(p.stock <= 0
                ? '"${p.name}" is out of stock.'
                : 'Only ${p.stock} of "${p.name}" left.');
          }
          items.add(OrderItem(
              productId: p.productId,
              name: p.name,
              price: p.price,
              quantity: l.quantity,
              imageUrl: p.imageUrl));
          subtotal += p.price * l.quantity;
        }

        final ref = _orders.doc();
        orders.add(CustomerOrder(
          orderId: ref.id,
          orderNumber: _orderNumber(ref.id),
          customerId: customerId,
          sellerId: shopData['sellerId'] as String? ?? g.shopId,
          shopId: g.shopId,
          shopName: shopName,
          items: items,
          subtotal: subtotal,
          shippingFee: area.shippingFee,
          total: subtotal + area.shippingFee,
          deliveryAddress: address,
          paymentMethod: method,
          paymentReference: paymentReference,
          createdAt: DateTime.now(),
        ));
      }

      // ---- 3. writes ----
      for (final o in orders) {
        tx.set(_orders.doc(o.orderId), o.toCreateMap());
      }
      if (clearCart) {
        final cart = _db
            .collection(Collections.users)
            .doc(customerId)
            .collection('cart');
        for (final g in groups) {
          for (final l in g.lines) {
            tx.delete(cart.doc(l.productId));
          }
        }
      }
      return orders;
    });
  }

  // ---------------------------------------------------------------------
  // Seller: accept (Pending -> Confirmed) and deduct stock safely.
  // ---------------------------------------------------------------------
  Future<void> acceptOrder(String orderId, String sellerId) =>
      _db.runTransaction((tx) async {
        final orderRef = _orders.doc(orderId);
        final snap = await tx.get(orderRef);
        if (!snap.exists) throw const AppException('This order no longer exists.');
        final order = CustomerOrder.fromMap(snap.data()!);

        if (order.sellerId != sellerId) {
          throw const AppException(
              "You don't have permission to perform this action.");
        }
        if (order.status != OrderStatus.pending) {
          throw AppException(
              'This order is already ${order.status.label.toLowerCase()}.');
        }
        if (order.inventoryDeducted) {
          throw const AppException('Stock was already deducted for this order.');
        }

        // Read every product first, then write.
        final stocks = <String, int>{};
        for (final item in order.items) {
          final p = await tx.get(_products.doc(item.productId));
          if (!p.exists) {
            throw AppException('"${item.name}" no longer exists.');
          }
          final stock = toInt(p.data()!['stock']);
          if (stock < item.quantity) {
            throw AppException(
                'Insufficient stock. "${item.name}" has only $stock left.');
          }
          stocks[item.productId] = stock;
        }

        for (final item in order.items) {
          // never below zero: guarded by the check above
          tx.update(_products.doc(item.productId), {
            'stock': stocks[item.productId]! - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        tx.update(orderRef, {
          'orderStatus': OrderStatus.confirmed.value,
          'inventoryDeducted': true,
          'statusTimes.${OrderStatus.confirmed.value}':
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  // ---------------------------------------------------------------------
  // Seller: reject, or move forward (Preparing -> Out for Delivery -> Delivered).
  // Inventory is never touched here.
  // ---------------------------------------------------------------------
  Future<void> changeStatus(String orderId, String sellerId, OrderStatus to) =>
      _db.runTransaction((tx) async {
        if (to == OrderStatus.confirmed) {
          throw const AppException('Accept the order to confirm it.');
        }
        if (to == OrderStatus.cancelled) {
          throw const AppException('Only the customer can cancel an order.');
        }
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw const AppException('This order no longer exists.');
        final order = CustomerOrder.fromMap(snap.data()!);

        if (order.sellerId != sellerId) {
          throw const AppException(
              "You don't have permission to perform this action.");
        }
        if (!order.status.canTransitionTo(to)) {
          throw AppException(
              'This order is ${order.status.label.toLowerCase()} and cannot be changed to ${to.label.toLowerCase()}.');
        }
        tx.update(ref, {
          'orderStatus': to.value,
          'statusTimes.${to.value}': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  // ---------------------------------------------------------------------
  // Customer: cancel while the order is still Pending. Stock is only ever
  // deducted on accept, so there is nothing to give back.
  // ---------------------------------------------------------------------
  Future<void> cancelOrder(String orderId, String customerId) =>
      _db.runTransaction((tx) async {
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw const AppException('This order no longer exists.');
        final order = CustomerOrder.fromMap(snap.data()!);

        if (order.customerId != customerId) {
          throw const AppException(
              "You don't have permission to perform this action.");
        }
        if (!order.status.canTransitionTo(OrderStatus.cancelled)) {
          throw AppException(
              'This order is already ${order.status.label.toLowerCase()} and can no longer be cancelled.');
        }
        tx.update(ref, {
          'orderStatus': OrderStatus.cancelled.value,
          'statusTimes.${OrderStatus.cancelled.value}':
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
}
