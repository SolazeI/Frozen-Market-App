import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cached network image with loading placeholder and broken-image fallback.
/// Fills its parent; pass [aspectRatio] to size it yourself.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.aspectRatio,
    this.fallbackIcon = Icons.ac_unit_rounded,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? aspectRatio;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    Widget child = (url == null || url!.isEmpty)
        ? _Placeholder(icon: fallbackIcon)
        : CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) =>
                _Placeholder(icon: fallbackIcon, loading: true),
            errorWidget: (_, __, ___) =>
                const _Placeholder(icon: Icons.broken_image_outlined),
          );

    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!, child: child);
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.loading = false});
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.ice,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: AppColors.primary, size: 36),
      );
}
