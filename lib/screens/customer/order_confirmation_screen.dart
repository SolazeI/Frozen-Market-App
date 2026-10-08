import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Screen 12: shown after a successful checkout (one card per seller order).
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orders});
  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: EmptyState(
          title: 'Nothing to show',
          message: 'Open My Orders to see your orders.',
          actionLabel: 'My orders',
          onAction: () => context.go(Routes.customerOrders),
        ),
      );
    }

    final grand = orders.fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Order placed'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: AppColors.successBg, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  size: 52, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 16),
          Text('Thank you! Your order was placed.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
              orders.length > 1
                  ? 'Your items were split into ${orders.length} orders, one per seller. Each seller will confirm theirs.'
                  : 'The seller will confirm your order shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          for (final o in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
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
                      const SizedBox(height: 4),
                      Text(o.shopName,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const Divider(height: 20),
                      Text(o.itemsSummary,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text(o.paymentMethod.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(Formatters.peso(o.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ]),
                      Text('incl. ${Formatters.peso(o.shippingFee)} shipping',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          if (orders.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Expanded(
                    child: Text('Grand total',
                        style: TextStyle(fontWeight: FontWeight.w800))),
                Text(Formatters.peso(grand),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.primary)),
              ]),
            ),
          const SizedBox(height: 12),
          FrostButton(
              label: 'View my orders',
              onPressed: () => context.go(Routes.customerOrders)),
          const SizedBox(height: 10),
          FrostButton(
              label: 'Continue shopping',
              style: FrostButtonStyle.outlined,
              onPressed: () => context.go(Routes.customerHome)),
        ],
      ),
    );
  }
}
