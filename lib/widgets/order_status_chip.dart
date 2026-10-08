import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../theme/app_colors.dart';

/// Colored pill showing an order's status.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      OrderStatus.pending => (AppColors.warning, AppColors.warningBg),
      OrderStatus.confirmed ||
      OrderStatus.preparing ||
      OrderStatus.outForDelivery =>
        (AppColors.primary, AppColors.ice),
      OrderStatus.delivered => (AppColors.success, AppColors.successBg),
      OrderStatus.rejected ||
      OrderStatus.cancelled =>
        (AppColors.error, AppColors.errorBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
