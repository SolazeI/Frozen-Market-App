import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/firestore_utils.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/review.dart';
import '../models/seller_review.dart';

/// Product reviews and seller ratings.
///  * A product review updates the PRODUCT's rating only.
///  * A seller rating (one per order) updates the SHOP's rating only.
/// Each review and its aggregate update are written in ONE transaction, so
/// averages can never drift from the reviews. Firestore rules re-check
/// every condition server-side.
class ReviewRepository {
  ReviewRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(Collections.reviews);
  CollectionReference<Map<String, dynamic>> get _sellerReviews =>
      _db.collection(Collections.sellerReviews);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(Collections.orders);
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(Collections.products);
  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection(Collections.shops);

  static void _validate(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw const AppException('Choose a rating from 1 to 5 stars.');
    }
    if (comment.length > Review.maxCommentLength) {
      throw const AppException(
          'Keep your review under ${Review.maxCommentLength} characters.');
    }
  }

  // ---------------------------------------------------------------- reads
  /// Newest first. Sorted client-side so no composite index is needed.
  List<Review> _parse(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map((d) => Review.fromMap(d.data())).toList();
    final now = DateTime.now();
    list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return list;
  }

  Stream<List<Review>> watchProductReviews(String productId) => _reviews
      .where('productId', isEqualTo: productId)
      .snapshots()
      .map(_parse);

  /// Reviews already written for one order (to hide the "Rate" button).
  Stream<List<Review>> watchOrderReviews(String orderId) =>
      _reviews.where('orderId', isEqualTo: orderId).snapshots().map(_parse);

  /// Seller ratings shown on the shop page, newest first.
  Stream<List<SellerReview>> watchShopSellerReviews(String shopId) =>
      _sellerReviews.where('shopId', isEqualTo: shopId).snapshots().map((s) {
        final list =
            s.docs.map((d) => SellerReview.fromMap(d.data())).toList();
        final now = DateTime.now();
        list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  /// The seller rating for one order, or null if not rated yet.
  Stream<SellerReview?> watchOrderSellerReview(String orderId) =>
      _sellerReviews.doc(orderId).snapshots().map((s) =>
          (s.exists && s.data() != null)
              ? SellerReview.fromMap(s.data()!)
              : null);

  // --------------------------------------------------------- product review
  Future<void> submitReview({
    required String orderId,
    required String productId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) {
    final text = comment.trim();
    _validate(rating, text);

    final reviewRef = _reviews.doc(Review.buildId(orderId, productId));

    return _db.runTransaction((tx) async {
      // ---- reads first ----
      final orderSnap = await tx.get(_orders.doc(orderId));
      if (!orderSnap.exists) {
        throw const AppException('This order no longer exists.');
      }
      final order = CustomerOrder.fromMap(orderSnap.data()!);
      if (order.customerId != customerId) {
        throw const AppException(
            "You don't have permission to perform this action.");
      }
      if (order.status != OrderStatus.delivered) {
        throw const AppException(
            'You can review items once the order is delivered.');
      }
      OrderItem? item;
      for (final i in order.items) {
        if (i.productId == productId) item = i;
      }
      if (item == null) {
        throw const AppException('That item is not part of this order.');
      }

      final existing = await tx.get(reviewRef);
      if (existing.exists) {
        throw const AppException('You already reviewed this item.');
      }

      final productRef = _products.doc(productId);
      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        throw const AppException('This product is no longer available.');
      }
      final p = productSnap.data()!;
      final pCount = toInt(p['reviewCount']);
      final pAvg = toDouble(p['rating']);

      // ---- writes ----
      tx.set(
        reviewRef,
        Review(
          reviewId: reviewRef.id,
          orderId: orderId,
          productId: productId,
          shopId: order.shopId,
          customerId: customerId,
          customerName: customerName,
          productName: item.name,
          rating: rating,
          comment: text,
        ).toCreateMap(),
      );
      // lastReviewId lets the security rules tie each rating change to
      // exactly one new review document.
      tx.update(productRef, {
        'rating': (pAvg * pCount + rating) / (pCount + 1),
        'reviewCount': pCount + 1,
        'lastReviewId': reviewRef.id,
      });
    });
  }

  // ---------------------------------------------------------- seller rating
  Future<void> submitSellerReview({
    required String orderId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) {
    final text = comment.trim();
    _validate(rating, text);

    final reviewRef = _sellerReviews.doc(orderId); // id == orderId: once per order

    return _db.runTransaction((tx) async {
      // ---- reads first ----
      final orderSnap = await tx.get(_orders.doc(orderId));
      if (!orderSnap.exists) {
        throw const AppException('This order no longer exists.');
      }
      final order = CustomerOrder.fromMap(orderSnap.data()!);
      if (order.customerId != customerId) {
        throw const AppException(
            "You don't have permission to perform this action.");
      }
      if (order.status != OrderStatus.delivered) {
        throw const AppException(
            'You can rate the seller once the order is delivered.');
      }

      final existing = await tx.get(reviewRef);
      if (existing.exists) {
        throw const AppException('You already rated the seller for this order.');
      }

      final shopRef = _shops.doc(order.shopId);
      final shopSnap = await tx.get(shopRef);
      if (!shopSnap.exists) {
        throw const AppException('This shop is no longer available.');
      }
      final s = shopSnap.data()!;
      final sCount = toInt(s['totalReviews']);
      final sAvg = toDouble(s['rating']);

      // ---- writes ----
      tx.set(
        reviewRef,
        SellerReview(
          orderId: orderId,
          shopId: order.shopId,
          customerId: customerId,
          customerName: customerName,
          rating: rating,
          comment: text,
        ).toCreateMap(),
      );
      tx.update(shopRef, {
        'rating': (sAvg * sCount + rating) / (sCount + 1),
        'totalReviews': sCount + 1,
        'lastReviewId': reviewRef.id,
      });
    });
  }
}
