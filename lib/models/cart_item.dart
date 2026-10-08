import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';

/// users/{uid}/cart/{productId}. Only ids + quantity are stored; prices and
/// stock are always read live from the product so the cart can never be stale.
class CartItem {
  const CartItem({
    required this.productId,
    required this.shopId,
    required this.quantity,
    this.selected = true,
    this.addedAt,
  });

  final String productId;
  final String shopId;
  final int quantity;
  final bool selected;
  final DateTime? addedAt;

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        productId: m['productId'] as String? ?? '',
        shopId: m['shopId'] as String? ?? '',
        quantity: toInt(m['quantity'], 1),
        selected: m['selected'] as bool? ?? true,
        addedAt: toDate(m['addedAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'productId': productId,
        'shopId': shopId,
        'quantity': quantity,
        'selected': selected,
        'addedAt': FieldValue.serverTimestamp(),
      };
}
