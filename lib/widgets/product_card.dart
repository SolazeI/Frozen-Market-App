import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_colors.dart';
import 'delivery_badge.dart';
import 'network_image_box.dart';
import 'rating_widgets.dart';

/// Marketplace product tile. Takes plain values (not a model) so it stays
/// reusable; screens map Product + delivery result into these params.
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
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  );

  @override
  Widget build(BuildContext context) {
    final outOfStock = stock <= 0;
    final t = Theme.of(context).textTheme;

    return Opacity(
      opacity: delivers ? 1 : 0.7,
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
                    if (outOfStock)
                      Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: const Text('Out of stock',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(Formatters.peso(price),
                        style: t.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    _IconLine(
                        icon: Icons.storefront_outlined, text: sellerName),
                    _IconLine(
                        icon: Icons.location_on_outlined,
                        text: sellerLocation),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingSummary(
                            rating: rating, reviewCount: reviewCount),
                        const Spacer(),
                        if (!outOfStock && stock <= 5)
                          Text('$stock left',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
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
