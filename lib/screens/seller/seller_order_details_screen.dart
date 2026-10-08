import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/order_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'order_actions.dart';

/// Screen 26: full order details for the seller.
class SellerOrderDetailsScreen extends ConsumerWidget {
  const SellerOrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(sellerOrderControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    final async = ref.watch(orderProvider(orderId));
    final order = async.valueOrNull;
    final showActions = order != null &&
        (order.status == OrderStatus.pending || order.status.actionLabel != null);

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
                onAction: () => context.pop())
            : _Body(order: o),
      ),
      bottomNavigationBar: showActions
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: OrderActions(order: order),
              ),
            )
          : null,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order});
  final CustomerOrder order;

  Widget _section(BuildContext context, String title, Widget child) => Padding(
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
                const SizedBox(height: 10),
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
  Widget build(BuildContext context) {
    final o = order;
    final a = o.deliveryAddress;
    final history = o.statusTimes.entries.toList()
      ..sort((x, y) => x.value.compareTo(y.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(
          context,
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
              if (o.status == OrderStatus.pending)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      'Accepting this order deducts the ordered quantities from your stock.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5)),
                ),
            ],
          ),
        ),
        _section(
          context,
          'Customer & delivery',
          Column(children: [
            _kv('Name', a.fullName),
            _kv('Phone', a.phone),
            _kv('Address', a.address),
            _kv('Location', a.location.fullLabel),
          ]),
        ),
        _section(
          context,
          'Items (${o.itemCount})',
          Column(
            children: [
              for (final i in o.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
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
                            Text('${i.quantity} × ${Formatters.peso(i.price)}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Text(Formatters.peso(i.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const Divider(),
              _kv('Subtotal', Formatters.peso(o.subtotal)),
              _kv('Shipping', Formatters.peso(o.shippingFee)),
              _kv('Total', Formatters.peso(o.total),
                  bold: true, color: AppColors.primary),
            ],
          ),
        ),
        _section(
          context,
          'Payment',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Method', o.paymentMethod.label),
              if (o.paymentMethod == PaymentMethod.gcash) ...[
                _kv('Reference', o.paymentReference ?? '—'),
                const Text('Verify the GCash payment before accepting.',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        if (history.isNotEmpty)
          _section(
            context,
            'History',
            Column(children: [
              for (final e in history)
                _kv(e.key.label, Formatters.dateTime(e.value)),
            ]),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
