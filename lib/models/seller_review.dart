import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';
import 'review.dart';

/// sellerReviews/{orderId}: the customer's rating of the seller for one
/// delivered order. The document id IS the order id, so an order can only
/// ever be rated once. The shop's rating is the average of these.
class SellerReview {
  const SellerReview({
    required this.orderId,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  final String orderId;
  final String shopId;
  final String customerId;
  final String customerName;
  final int rating; // 1..5
  final String comment;
  final DateTime? createdAt;

  String get displayName => Review.maskName(customerName);

  factory SellerReview.fromMap(Map<String, dynamic> m) => SellerReview(
        orderId: m['orderId'] as String? ?? '',
        shopId: m['shopId'] as String? ?? '',
        customerId: m['customerId'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        rating: toInt(m['rating']),
        comment: m['comment'] as String? ?? '',
        createdAt: toDate(m['createdAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'reviewId': orderId,
        'orderId': orderId,
        'shopId': shopId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
