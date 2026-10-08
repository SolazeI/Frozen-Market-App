import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/order_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Seller buttons for an order: Accept/Reject while pending, then the next
/// step in the flow. Errors (e.g. "Insufficient stock.") are shown by the
/// screen that listens to [sellerOrderControllerProvider].
class OrderActions extends ConsumerWidget {
  const OrderActions({super.key, required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(sellerOrderControllerProvider).isLoading;
    final ctrl = ref.read(sellerOrderControllerProvider.notifier);

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await showConfirmDialog(context,
                          title: 'Reject this order?',
                          message:
                              '${order.orderNumber} will be rejected. Your stock will not change.',
                          confirmLabel: 'Reject',
                          isDestructive: true);
                      if (!ok) return;
                      final done = await ctrl.reject(order);
                      if (done && context.mounted) {
                        AppSnackbar.info(context, 'Order rejected');
                      }
                    },
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: busy
                  ? null
                  : () async {
                      final done = await ctrl.accept(order);
                      if (done && context.mounted) {
                        AppSnackbar.success(
                            context, 'Order accepted. Stock updated.');
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Text('Accept'),
            ),
          ),
        ],
      );
    }

    final label = order.status.actionLabel;
    if (label == null) return const SizedBox.shrink();
    return FilledButton(
      onPressed: busy
          ? null
          : () async {
              final next = order.status.next!;
              final done = await ctrl.advance(order);
              if (done && context.mounted) {
                AppSnackbar.success(context, 'Order is now ${next.label}');
              }
            },
      child: Text(label),
    );
  }
}
