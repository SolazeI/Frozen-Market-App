import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_colors.dart';
import 'delivery_badge.dart';
import 'network_image_box.dart';

/// Marketplace product tile. Takes plain values (not a model) so it stays
/// reusable; screens map Product + delivery result into these params.
///
/// Layout: big photo with overlays (rating bottom-left, "n left" top-left,
/// "Sold out" veil), then name, price, seller, location and delivery pill.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.sellerName,
    required this.sellerLocation,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.delivers,
    required this.isLocal,
    this.shippingFee,
    this.imageUrl,
    this.onTap,
  });

  final String name;
  final double price;
  final String sellerName;
  final String sellerLocation;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool delivers;
  final bool isLocal;
  final double? shippingFee;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Responsive grid: 2 columns on phones, more on tablets.
  static const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    childAspectRatio: 0.56,
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
  );

  @override
  Widget build(BuildContext context) {
    final outOfStock = stock <= 0;
    final lowStock = !outOfStock && stock <= 5;
    final t = Theme.of(context).textTheme;

    return Opacity(
      opacity: delivers ? 1 : 0.72,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageBox(url: imageUrl),
                    // Soft bottom scrim so the rating pill stays readable.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x33000000),
                          ],
                        ),
                      ),
                    ),
                    if (lowStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Pill(
                          text: 'Only $stock left',
                          background: AppColors.warning,
                          foreground: Colors.white,
                        ),
                      ),
                    if (reviewCount > 0)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _RatingPill(rating: rating, count: reviewCount),
                      ),
                    if (outOfStock)
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const _Pill(
                          text: 'Sold out',
                          background: Colors.white,
                          foreground: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, height: 1.25)),
                    const SizedBox(height: 4),
                    Text(Formatters.peso(price),
                        style: t.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    _IconLine(
                        icon: Icons.storefront_outlined, text: sellerName),
                    if (sellerLocation.isNotEmpty)
                      _IconLine(
                          icon: Icons.location_on_outlined,
                          text: sellerLocation),
                    const SizedBox(height: 8),
                    DeliveryBadge(
                      delivers: delivers,
                      isLocal: isLocal,
                      shippingFee: shippingFee,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.text, required this.background, required this.foreground});
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: foreground, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w800)),
            Text(' ($count)',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}
