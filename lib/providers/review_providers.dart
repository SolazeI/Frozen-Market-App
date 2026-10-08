import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/seller_review.dart';
import '../repositories/review_repository.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

final reviewRepositoryProvider =
    Provider((ref) => ReviewRepository(ref.watch(firestoreProvider)));

final productReviewsProvider = StreamProvider.autoDispose
    .family<List<Review>, String>((ref, productId) =>
        ref.watch(reviewRepositoryProvider).watchProductReviews(productId));

/// Product reviews already written for an order.
final orderReviewsProvider = StreamProvider.autoDispose
    .family<List<Review>, String>((ref, orderId) =>
        ref.watch(reviewRepositoryProvider).watchOrderReviews(orderId));

/// Seller ratings for a shop (shown on the shop page).
final shopSellerReviewsProvider = StreamProvider.autoDispose
    .family<List<SellerReview>, String>((ref, shopId) =>
        ref.watch(reviewRepositoryProvider).watchShopSellerReviews(shopId));

/// The seller rating for an order (null = not rated yet).
final orderSellerReviewProvider = StreamProvider.autoDispose
    .family<SellerReview?, String>((ref, orderId) =>
        ref.watch(reviewRepositoryProvider).watchOrderSellerReview(orderId));

final reviewControllerProvider =
    AsyncNotifierProvider<ReviewController, void>(ReviewController.new);

class ReviewController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> _run(Future<void> Function(String uid, String name) action) async {
    final user = ref.read(currentUserProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (user == null || !user.isCustomer) {
        throw const AppException(
            "You don't have permission to perform this action.");
      }
      await action(user.uid, user.fullName);
    });
    return !state.hasError;
  }

  /// Rates one product of a delivered order. Returns true on success.
  Future<bool> submit({
    required CustomerOrder order,
    required String productId,
    required int rating,
    required String comment,
  }) =>
      _run((uid, name) => ref.read(reviewRepositoryProvider).submitReview(
            orderId: order.orderId,
            productId: productId,
            customerId: uid,
            customerName: name,
            rating: rating,
            comment: comment,
          ));

  /// Rates the seller of a delivered order (once per order).
  Future<bool> submitSeller({
    required CustomerOrder order,
    required int rating,
    required String comment,
  }) =>
      _run((uid, name) => ref.read(reviewRepositoryProvider).submitSellerReview(
            orderId: order.orderId,
            customerId: uid,
            customerName: name,
            rating: rating,
            comment: comment,
          ));
}
