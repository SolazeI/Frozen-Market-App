import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/review.dart';
import '../../providers/order_providers.dart';
import '../../providers/review_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'review_sheet.dart';

/// Customer order details: live status timeline, items (with Rate buttons once
/// delivered), delivery, payment and totals. The order is a live Firestore
/// stream, so status changes made by the seller appear without refreshing.
class CustomerOrderDetailsScreen extends ConsumerWidget {
  const CustomerOrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, CustomerOrder o) async {
    final ok = await showConfirmDialog(context,
        title: 'Cancel this order?',
        message:
            '${o.orderNumber} will be cancelled. You can only cancel while the seller has not accepted it yet.',
        confirmLabel: 'Cancel order',
        cancelLabel: 'Keep order',
        isDestructive: true);
    if (!ok) return;
    final done = await ref.read(customerOrderControllerProvider.notifier).cancel(o);
    if (done && context.mounted) AppSnackbar.info(context, 'Order cancelled');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(customerOrderControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    final async = ref.watch(orderProvider(orderId));
    final order = async.valueOrNull;
    final busy = ref.watch(customerOrderControllerProvider).isLoading;
    final canCancel = order != null && order.status == OrderStatus.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: AsyncValueView<CustomerOrder?>(
        value: async,
        onRetry: () => ref.invalidate(orderProvider(orderId)),
        data: (o) => o == null
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Order not found',
                actionLabel: 'Back',
                onAction: () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.customerOrders))
            : _Body(order: o),
      ),
      bottomNavigationBar: canCancel
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FrostButton(
                  label: 'Cancel order',
                  style: FrostButtonStyle.outlined,
                  isLoading: busy,
                  onPressed: () => _cancel(context, ref, order),
                ),
              ),
            )
          : null,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});
  final CustomerOrder order;

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      );

  Widget _kv(String k, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 96,
                child: Text(k,
                    style: const TextStyle(color: AppColors.textSecondary))),
            Expanded(
                child: Text(v,
                    style: TextStyle(
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: color))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = order;
    final a = o.deliveryAddress;
    final delivered = o.status == OrderStatus.delivered;

    // productId -> review, for items already rated in this order.
    final reviews = {
      for (final r in ref.watch(orderReviewsProvider(o.orderId)).valueOrNull ??
          const <Review>[])
        r.productId: r
    };

    final sellerReview =
        ref.watch(orderSellerReviewProvider(o.orderId)).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(
          o.orderNumber,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                OrderStatusChip(status: o.status),
                const Spacer(),
                if (o.createdAt != null)
                  Text(Formatters.dateTime(o.createdAt!),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5)),
              ]),
              const SizedBox(height: 4),
              Text(o.shopName,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OrderTimeline(status: o.status, times: o.statusTimes),
            ],
          ),
        ),
        if (delivered)
          _section(
            'Seller rating',
            sellerReview != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRow(rating: sellerReview.rating, size: 22),
                      if (sellerReview.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(sellerReview.comment,
                            style: const TextStyle(height: 1.35)),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How was your experience with ${o.shopName}?',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      FrostButton(
                        label: 'Rate seller',
                        icon: Icons.storefront_outlined,
                        onPressed: () =>
                            showSellerReviewSheet(context, order: o),
                      ),
                    ],
                  ),
          ),
        _section(
          'Items (${o.itemCount})',
          Column(
            children: [
              for (final i in o.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: NetworkImageBox(
                                url: i.imageUrl,
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    '${i.quantity} × ${Formatters.peso(i.price)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5)),
                              ],
                            ),
                          ),
                          Text(Formatters.peso(i.subtotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (delivered)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: reviews[i.productId] != null
                              ? Row(children: [
                                  const Text('Your rating  ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5)),
                                  StarRow(
                                      rating: reviews[i.productId]!.rating,
                                      size: 16),
                                ])
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => showReviewSheet(context,
                                        order: o, item: i),
                                    icon: const Icon(Icons.star_outline_rounded,
                                        size: 18),
                                    label: const Text('Rate this product'),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              _kv('Subtotal', Formatters.peso(o.subtotal)),
              _kv('Shipping', Formatters.peso(o.shippingFee)),
              _kv('Total', Formatters.peso(o.total),
                  bold: true, color: AppColors.primary),
            ],
          ),
        ),
        _section(
          'Delivery',
          Column(children: [
            _kv('Name', a.fullName),
            _kv('Phone', a.phone),
            _kv('Address', a.address),
            _kv('Location', a.location.fullLabel),
          ]),
        ),
        _section(
          'Payment',
          Column(children: [
            _kv('Method', o.paymentMethod.label),
            if (o.paymentMethod == PaymentMethod.gcash)
              _kv('Reference', o.paymentReference ?? '—'),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
