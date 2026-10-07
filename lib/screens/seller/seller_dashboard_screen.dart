import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/seller_stats.dart';
import '../../models/shop.dart';
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
                orElse: () => const SizedBox(
                    height: 160, child: LoadingView()),
              ),
              const SectionHeader(
                  title: 'Quick actions',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              const _QuickActions(),
              const SectionHeader(
                  title: 'Recent orders',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text("You don't have any orders yet.",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
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
    final location = [shop.city, shop.province]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.storefront, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    void soon(String what) =>
        AppSnackbar.info(context, '$what is coming soon.');

    final actions = <(IconData, String, VoidCallback)>[
      (Icons.add_box_outlined, 'Add product',
          () => context.go(Routes.sellerProducts)),
      (Icons.inventory_2_outlined, 'Products',
          () => context.go(Routes.sellerProducts)),
      (Icons.receipt_long_outlined, 'Orders',
          () => context.go(Routes.sellerOrders)),
      (Icons.local_shipping_outlined, 'Delivery areas',
          () => soon('Delivery areas')),
      (Icons.settings_outlined, 'Shop settings',
          () => context.push(Routes.editShop)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final a in actions)
          Card(
            child: InkWell(
              onTap: a.$3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.$1, color: AppColors.primary, size: 28),
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
