import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';

/// reviews/{orderId}_{productId}. The deterministic id means a customer can
/// review each product of an order exactly once (no duplicates).
class Review {
  const Review({
    required this.reviewId,
    required this.orderId,
    required this.productId,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.productName,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  final String reviewId;
  final String orderId;
  final String productId;
  final String shopId;
  final String customerId;
  final String customerName;
  final String productName;
  final int rating; // 1..5
  final String comment;
  final DateTime? createdAt;

  static const maxCommentLength = 500;

  static String buildId(String orderId, String productId) =>
      '${orderId}_$productId';

  /// "Juan Dela Cruz" -> "Juan C." (reviews are public).
  String get displayName => maskName(customerName);

  static String maskName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Customer';
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0].toUpperCase()}.';
  }

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        reviewId: m['reviewId'] as String? ?? '',
        orderId: m['orderId'] as String? ?? '',
        productId: m['productId'] as String? ?? '',
        shopId: m['shopId'] as String? ?? '',
        customerId: m['customerId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        productName: m['productName'] as String? ?? '',
        rating: toInt(m['rating']),
        comment: m['comment'] as String? ?? '',
        createdAt: toDate(m['createdAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'reviewId': reviewId,
        'orderId': orderId,
        'productId': productId,
        'shopId': shopId,
        'customerId': customerId,
        'customerName': customerName,
        'productName': productName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
