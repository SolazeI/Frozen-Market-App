import 'package:flutter/material.dart';

/// Title row with optional "See all" action, e.g. "Nearby products".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'See all',
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 12),
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      );
}
