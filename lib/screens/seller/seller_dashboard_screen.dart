import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/seller_stats.dart';
import '../../models/shop.dart';
import '../../providers/order_providers.dart';
import '../../providers/shop_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(myShopProvider);
    final stats = ref.watch(sellerStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: AsyncValueView<Shop?>(
        value: shop,
        onRetry: () => ref.invalidate(myShopProvider),
        data: (s) {
          if (s == null) {
            return const ErrorState(
                title: 'Shop not found',
                message:
                    "We couldn't find your shop. Please log out and try again.");
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ShopHeader(shop: s),
              const SizedBox(height: 16),
              stats.maybeWhen(
                data: (st) => _StatsGrid(stats: st),
                orElse: () =>
                    const SizedBox(height: 160, child: LoadingView()),
              ),
              const SectionHeader(
                  title: 'Quick actions',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              const _QuickActions(),
              SectionHeader(
                  title: 'Recent orders',
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                  onAction: () => context.go(Routes.sellerOrders)),
              const _RecentOrders(),
            ],
          );
        },
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final location =
        [shop.city, shop.province].where((s) => s.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: NetworkImageBox(
              url: shop.logoUrl,
              fallbackIcon: Icons.storefront,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(shop.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                if (location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.white70),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final SellerStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Total products',
            value: '${stats.totalProducts}'),
        StatCard(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending orders',
            value: '${stats.pendingOrders}',
            color: AppColors.warning,
            background: AppColors.warningBg),
        StatCard(
            icon: Icons.payments_outlined,
            label: 'Total sales',
            value: Formatters.peso(stats.totalSales),
            color: AppColors.success,
            background: AppColors.successBg),
        StatCard(
            icon: Icons.star_rounded,
            label: stats.totalReviews == 0
                ? 'Shop rating'
                : 'Shop rating (${stats.totalReviews})',
            value: stats.totalReviews == 0
                ? 'No ratings'
                : stats.rating.toStringAsFixed(1),
            color: AppColors.star,
            background: AppColors.warningBg),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, Color, Color, VoidCallback)>[
      (Icons.add_box_outlined, 'Add product', AppColors.primary, AppColors.ice,
          () => context.push(Routes.productAdd)),
      (Icons.inventory_2_outlined, 'Products', AppColors.accent,
          const Color(0xFFE1F5FE), () => context.go(Routes.sellerProducts)),
      (Icons.receipt_long_outlined, 'Orders', AppColors.warning,
          AppColors.warningBg, () => context.go(Routes.sellerOrders)),
      (Icons.local_shipping_outlined, 'Delivery areas', AppColors.success,
          AppColors.successBg, () => context.push(Routes.deliveryAreas)),
      (Icons.settings_outlined, 'Shop settings', AppColors.textSecondary,
          const Color(0xFFEAEFF4), () => context.push(Routes.editShop)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.98,
      children: [
        for (final a in actions)
          Card(
            child: InkWell(
              onTap: a.$5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: a.$4, borderRadius: BorderRadius.circular(14)),
                    child: Icon(a.$1, color: a.$3, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(a.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Latest three orders on the dashboard.
class _RecentOrders extends ConsumerWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders =
        ref.watch(sellerOrdersProvider).valueOrNull ?? const <CustomerOrder>[];
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text("You don't have any orders yet.",
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final o in orders.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                title: Text(o.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    '${o.deliveryAddress.fullName} • ${Formatters.peso(o.total)}'),
                trailing: OrderStatusChip(status: o.status),
                onTap: () => context.push(Routes.sellerOrder(o.orderId)),
              ),
            ),
          ),
      ],
    );
  }
}
