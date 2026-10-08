import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';
import 'order_status.dart';
import 'psgc_location.dart';

enum PaymentMethod {
  cod('cod', 'Cash on Delivery'),
  gcash('gcash', 'GCash');

  const PaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static PaymentMethod parse(String? v) => PaymentMethod.values
      .firstWhere((m) => m.value == v, orElse: () => PaymentMethod.cod);
}

/// A product line inside an order (price is a snapshot at purchase time).
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        price: toDouble(m['price']),
        quantity: toInt(m['quantity'], 1),
        imageUrl: m['imageUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.location,
  });

  final String fullName;
  final String phone;
  final String address; // street / house no.
  final PsgcLocation location;

  String get fullLabel => '$address, ${location.fullLabel}';

  factory DeliveryAddress.fromMap(Map<String, dynamic> m) => DeliveryAddress(
        fullName: m['fullName'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        address: m['address'] as String? ?? '',
        location: PsgcLocation.fromMap(m),
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'address': address,
        ...location.toMap(),
      };
}

/// orders/{orderId}: one order per seller. [shopId] == [sellerId].
class CustomerOrder {
  const CustomerOrder({
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentReference,
    this.status = OrderStatus.pending,
    this.inventoryDeducted = false,
    this.statusTimes = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final String orderNumber;
  final String customerId;
  final String sellerId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final DeliveryAddress deliveryAddress;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final OrderStatus status;
  final bool inventoryDeducted;
  final Map<OrderStatus, DateTime> statusTimes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  String get itemsSummary =>
      items.map((i) => '${i.quantity}× ${i.name}').join(', ');

  factory CustomerOrder.fromMap(Map<String, dynamic> m) {
    final times = <OrderStatus, DateTime>{};
    final raw = m['statusTimes'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final d = toDate(v);
        if (d != null) times[OrderStatus.parse(k as String)] = d;
      });
    }
    return CustomerOrder(
      orderId: m['orderId'] as String? ?? '',
      orderNumber: m['orderNumber'] as String? ?? '',
      customerId: m['customerId'] as String? ?? '',
      sellerId: m['sellerId'] as String? ?? '',
      shopId: m['shopId'] as String? ?? '',
      shopName: m['shopName'] as String? ?? '',
      items: ((m['items'] as List?) ?? const [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: toDouble(m['subtotal']),
      shippingFee: toDouble(m['shippingFee']),
      total: toDouble(m['total']),
      deliveryAddress: DeliveryAddress.fromMap(
          Map<String, dynamic>.from((m['deliveryAddress'] as Map?) ?? {})),
      paymentMethod: PaymentMethod.parse(m['paymentMethod'] as String?),
      paymentReference: m['paymentReference'] as String?,
      status: OrderStatus.parse(m['orderStatus'] as String?),
      inventoryDeducted: m['inventoryDeducted'] as bool? ?? false,
      statusTimes: times,
      createdAt: toDate(m['createdAt']),
      updatedAt: toDate(m['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'customerId': customerId,
        'sellerId': sellerId,
        'shopId': shopId,
        'shopName': shopName,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'total': total,
        'deliveryAddress': deliveryAddress.toMap(),
        'paymentMethod': paymentMethod.value,
        'paymentReference': paymentReference,
        'orderStatus': OrderStatus.pending.value,
        'inventoryDeducted': false,
        'statusTimes': {OrderStatus.pending.value: FieldValue.serverTimestamp()},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
