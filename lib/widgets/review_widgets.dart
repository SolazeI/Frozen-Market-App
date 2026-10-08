import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/formatters.dart';
import '../models/review.dart';
import '../models/seller_review.dart';
import '../providers/review_providers.dart';
import '../theme/app_colors.dart';
import 'rating_widgets.dart';
import 'state_views.dart';

/// Read-only row of five stars.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < rating ? AppColors.star : AppColors.border,
            ),
        ],
      );
}

/// One public review: first name + last initial, stars, date, comment.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.showProduct = false});
  final Review review;
  final bool showProduct;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(review.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (review.createdAt != null)
                  Text(Formatters.date(review.createdAt!),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 2),
            StarRow(rating: review.rating),
            if (showProduct && review.productName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(review.productName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment, style: const TextStyle(height: 1.35)),
            ],
          ],
        ),
      );
}

/// Reviews block for the product page (latest five).
class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection(
      {super.key,
      required this.productId,
      required this.rating,
      required this.reviewCount});
  final String productId;
  final double rating;
  final int reviewCount;

  static const _limit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productReviewsProvider(productId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Reviews',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                RatingSummary(rating: rating, reviewCount: reviewCount),
              ],
            ),
            const SizedBox(height: 4),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("We couldn't load reviews right now.",
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'No reviews yet. Customers can review a product after their order is delivered.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                final shown = list.take(_limit).toList();
                return Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ReviewTile(review: shown[i]),
                    ],
                    if (list.length > _limit)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'Showing the latest $_limit of ${list.length} reviews',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One seller rating: first name + last initial, stars, date, comment.
class SellerReviewTile extends StatelessWidget {
  const SellerReviewTile({super.key, required this.review});
  final SellerReview review;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(review.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (review.createdAt != null)
                  Text(Formatters.date(review.createdAt!),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 2),
            StarRow(rating: review.rating),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment, style: const TextStyle(height: 1.35)),
            ],
          ],
        ),
      );
}

/// Seller ratings for the shop page's Reviews tab.
class ShopReviewsList extends ConsumerWidget {
  const ShopReviewsList({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AsyncValueView<List<SellerReview>>(
        value: ref.watch(shopSellerReviewsProvider(shopId)),
        onRetry: () => ref.invalidate(shopSellerReviewsProvider(shopId)),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyState(
            icon: Icons.star_outline_rounded,
            title: 'No seller ratings yet',
            message: 'Customers can rate the seller once their order is delivered.'),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => SellerReviewTile(review: list[i]),
        ),
      );
}
