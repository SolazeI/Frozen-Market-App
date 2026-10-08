import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'product_card.dart';

/// Pulsing placeholder block. All skeletons share one animation look.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<Color?> _color = ColorTween(
    begin: AppColors.ice.withValues(alpha: 0.55),
    end: AppColors.ice,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _color,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _color.value,
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.circle ? null : BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// Placeholder shaped like [ProductCard].
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) => const Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: SkeletonBox(width: double.infinity, radius: 0)),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 12, width: double.infinity),
                  SizedBox(height: 6),
                  SkeletonBox(height: 12, width: 90),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16, width: 70),
                  SizedBox(height: 10),
                  SkeletonBox(height: 10, width: 110),
                  SizedBox(height: 6),
                  SkeletonBox(height: 10, width: 80),
                  SizedBox(height: 12),
                  SkeletonBox(height: 20, width: 120, radius: 8),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Grid of product skeletons (home, search, shop pages).
class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({super.key, this.count = 6, this.shrinkWrap = false});
  final int count;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(16),
        gridDelegate: ProductCard.gridDelegate,
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonProductCard(),
      );
}

/// Placeholder for card-style list rows (orders, products, areas).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5, this.itemHeight = 92});
  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: itemHeight - 24,
              child: const Row(
                children: [
                  SkeletonBox(width: 64, height: 64, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonBox(height: 13, width: double.infinity),
                        SizedBox(height: 8),
                        SkeletonBox(height: 13, width: 120),
                        SizedBox(height: 8),
                        SkeletonBox(height: 11, width: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
