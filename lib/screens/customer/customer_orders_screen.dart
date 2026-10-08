import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/order_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Orders tab: the customer's orders, newest first. Tap one to track it.
class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: AsyncValueView<List<CustomerOrder>>(
        value: ref.watch(customerOrdersProvider),
        onRetry: () => ref.invalidate(customerOrdersProvider),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: "You don't have any orders yet.",
          message: 'Your orders will show up here.',
        ),
        data: (orders) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final o = orders[i];
            return Card(
              child: InkWell(
                onTap: () => context.push(Routes.customerOrder(o.orderId)),
                child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(o.orderNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                      OrderStatusChip(status: o.status),
                    ]),
                    const SizedBox(height: 2),
                    Text(o.shopName,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(o.itemsSummary,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(o.paymentMethod.label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5)),
                      if (o.createdAt != null) ...[
                        const Text('  •  ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(Formatters.date(o.createdAt!),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5)),
                      ],
                      const Spacer(),
                      Text(Formatters.peso(o.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ]),
                  ],
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}
