import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Title row with a brand accent bar and optional "See all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'See all',
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Container(
              width: 4,
              height: subtitle == null ? 20 : 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      );
}
