import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Horizontally scrolling category filter. [selected] == 'All' means no filter.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories = ProductCategories.list,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final items = [ProductCategories.all, ...categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = items[i];
          final isSelected = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(label),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}
