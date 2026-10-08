import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../models/order.dart';
import '../../models/review.dart';
import '../../providers/review_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Bottom sheet to rate one delivered item (1-5 stars + optional comment).
Future<void> showReviewSheet(
  BuildContext context, {
  required CustomerOrder order,
  required OrderItem item,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RatingSheet(
        title: 'Rate this product',
        subtitle: item.name,
        successMessage: 'Thanks for your review!',
        onSubmit: (ref, stars, comment) =>
            ref.read(reviewControllerProvider.notifier).submit(
                  order: order,
                  productId: item.productId,
                  rating: stars,
                  comment: comment,
                ),
      ),
    );

/// Bottom sheet to rate the seller of a delivered order (once per order).
Future<void> showSellerReviewSheet(
  BuildContext context, {
  required CustomerOrder order,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RatingSheet(
        title: 'Rate the seller',
        subtitle: order.shopName,
        successMessage: 'Thanks for rating the seller!',
        onSubmit: (ref, stars, comment) =>
            ref.read(reviewControllerProvider.notifier).submitSeller(
                  order: order,
                  rating: stars,
                  comment: comment,
                ),
      ),
    );

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({
    required this.title,
    required this.subtitle,
    required this.successMessage,
    required this.onSubmit,
  });
  final String title;
  final String subtitle;
  final String successMessage;
  final Future<bool> Function(WidgetRef ref, int stars, String comment)
      onSubmit;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  int _stars = 0;
  bool _showStarError = false;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _showStarError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await widget.onSubmit(ref, _stars, _comment.text);
    if (ok && mounted) {
      AppSnackbar.success(context, widget.successMessage);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(reviewControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final saving = ref.watch(reviewControllerProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Center(
              child: StarRatingInput(
                  value: _stars,
                  onChanged: saving
                      ? (_) {}
                      : (v) => setState(() {
                            _stars = v;
                            _showStarError = false;
                          })),
            ),
            if (_showStarError)
              const Center(
                child: Text('Tap a star to rate',
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: Review.maxCommentLength,
              enabled: !saving,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FrostButton(label: 'Submit', isLoading: saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
