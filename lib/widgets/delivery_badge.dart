import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_colors.dart';

/// Shows delivery availability for the customer's selected location (Rules 1-3).
///  - not delivered     -> "Not available in your area" (red)
///  - delivered, local  -> "Delivers to your location" (green)
///  - delivered, remote -> "Shipping: ₱80" (orange)
class DeliveryBadge extends StatelessWidget {
  const DeliveryBadge({
    super.key,
    required this.delivers,
    this.isLocal = false,
    this.shippingFee,
    this.dense = true,
  });

  final bool delivers;
  final bool isLocal;
  final double? shippingFee;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final IconData icon;
    final String text;

    if (!delivers) {
      fg = AppColors.error;
      bg = AppColors.errorBg;
      icon = Icons.block_rounded;
      text = 'Not available in your area';
    } else if (isLocal) {
      fg = AppColors.success;
      bg = AppColors.successBg;
      icon = Icons.check_circle_rounded;
      text = shippingFee == null
          ? 'Delivers to your location'
          : 'Delivers here • ${Formatters.peso(shippingFee!)}';
    } else {
      fg = AppColors.warning;
      bg = AppColors.warningBg;
      icon = Icons.local_shipping_rounded;
      text = 'Shipping: ${Formatters.peso(shippingFee ?? 0)}';
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 14, vertical: dense ? 4 : 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(dense ? 20 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 17, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: dense ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
