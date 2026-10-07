import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact read-only rating: ★ 4.6 (120). Shows "No reviews yet" when count is 0.
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 14,
  });

  final double rating;
  final int reviewCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style =
        TextStyle(fontSize: size - 3, color: AppColors.textSecondary);
    if (reviewCount == 0) return Text('No reviews', style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.star, size: size + 2),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: style.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text('($reviewCount)', style: style),
      ],
    );
  }
}

/// Tappable 1–5 star input for the review screen.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < value;
          return IconButton(
            padding: EdgeInsets.zero,
            constraints:
                BoxConstraints.tightFor(width: size + 8, height: size + 8),
            iconSize: size,
            onPressed: () => onChanged(i + 1),
            icon: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? AppColors.star : AppColors.border,
            ),
          );
        }),
      );
}
