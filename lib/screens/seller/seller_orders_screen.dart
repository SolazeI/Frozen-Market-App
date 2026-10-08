import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/order_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'order_actions.dart';

/// Seller orders, filtered by status tabs.
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  static const _tabs = <(String, List<OrderStatus>)>[
    ('Pending', [OrderStatus.pending]),
    ('Confirmed', [OrderStatus.confirmed]),
    ('Preparing', [OrderStatus.preparing]),
    ('Out for Delivery', [OrderStatus.outForDelivery]),
    ('Delivered', [OrderStatus.delivered]),
    ('Rejected', [OrderStatus.rejected, OrderStatus.cancelled]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(sellerOrderControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    final async = ref.watch(sellerOrdersProvider);
    final all = async.valueOrNull ?? const <CustomerOrder>[];

    int count(List<OrderStatus> s) =>
        all.where((o) => s.contains(o.status)).length;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              for (final t in _tabs)
                Tab(text: all.isEmpty ? t.$1 : '${t.$1} (${count(t.$2)})'),
            ],
          ),
        ),
        body: AsyncValueView<List<CustomerOrder>>(
          value: async,
          onRetry: () => ref.invalidate(sellerOrdersProvider),
          isEmpty: (l) => l.isEmpty,
          empty: const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: "You don't have any orders yet.",
            message: 'Incoming orders will appear here.',
          ),
          data: (orders) => TabBarView(
            children: [
              for (final t in _tabs)
                _OrderList(
                  label: t.$1,
                  orders: orders.where((o) => t.$2.contains(o.status)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.label, required this.orders});
  final String label;
  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No ${label.toLowerCase()} orders',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => SellerOrderCard(order: orders[i]),
    );
  }
}

class SellerOrderCard extends StatelessWidget {
  const SellerOrderCard({super.key, required this.order, this.showActions = true});
  final CustomerOrder order;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final hasActions = showActions &&
        (o.status == OrderStatus.pending || o.status.actionLabel != null);

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.sellerOrder(o.orderId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(o.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                OrderStatusChip(status: o.status),
              ]),
              const SizedBox(height: 4),
              Text(
                  '${o.deliveryAddress.fullName} • ${o.deliveryAddress.location.shortLabel}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(o.itemsSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                Text(Formatters.peso(o.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16)),
                const Spacer(),
                Text(o.paymentMethod.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ]),
              if (o.createdAt != null)
                Text(Formatters.dateTime(o.createdAt!),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              if (hasActions) ...[
                const SizedBox(height: 12),
                OrderActions(order: o),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
