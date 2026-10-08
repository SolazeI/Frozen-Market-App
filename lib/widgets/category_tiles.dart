import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Home-screen category shortcuts: rounded icon tile + label.
/// (Use [CategoryChips] for filter rows; this is for browsing.)
class CategoryTiles extends StatelessWidget {
  const CategoryTiles({
    super.key,
    required this.onSelected,
    this.categories = ProductCategories.list,
  });

  final ValueChanged<String> onSelected;
  final List<String> categories;

  static IconData iconFor(String category) => switch (category) {
        'Frozen Meat' => Icons.kebab_dining,
        'Seafood' => Icons.set_meal,
        'Chicken' => Icons.lunch_dining,
        'Pork' => Icons.restaurant,
        'Beef' => Icons.outdoor_grill,
        'Ready-to-Cook' => Icons.microwave,
        'Processed Food' => Icons.fastfood,
        'Frozen Vegetables' => Icons.eco,
        _ => Icons.category,
      };

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = categories[i];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(c),
              child: SizedBox(
                width: 74,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Icon(iconFor(c),
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(c,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
