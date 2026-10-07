import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FrostButtonStyle { primary, outlined, danger }

/// App-wide button with built-in loading state (disables taps while loading).
class FrostButton extends StatelessWidget {
  const FrostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style = FrostButtonStyle.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final FrostButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: style == FrostButtonStyle.outlined
                  ? AppColors.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    switch (style) {
      case FrostButtonStyle.outlined:
        return OutlinedButton(onPressed: onTap, child: child);
      case FrostButtonStyle.danger:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: onTap,
          child: child,
        );
      case FrostButtonStyle.primary:
        return FilledButton(onPressed: onTap, child: child);
    }
  }
}
