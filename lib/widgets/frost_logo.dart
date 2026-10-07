import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Brand mark: snowflake in a ring, with optional name and tagline.
/// Set [onDark] for use on the blue splash/auth header.
class FrostLogo extends StatelessWidget {
  const FrostLogo({
    super.key,
    this.size = 88,
    this.showName = true,
    this.showTagline = false,
    this.onDark = false,
  });

  final double size;
  final bool showName;
  final bool showTagline;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.primary;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: fg, width: size * 0.035),
            color: onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.ice,
          ),
          child: Icon(Icons.ac_unit_rounded, color: fg, size: size * 0.52),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.2),
          Text(
            AppConstants.appName,
            style: textTheme.headlineMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: onDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
