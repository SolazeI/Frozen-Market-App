import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/delivery_area.dart';
import '../../models/market_item.dart';
import '../../models/shop.dart';
import '../../providers/location_providers.dart';
import '../../providers/marketplace_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Public shop page: header, products, delivery areas and reviews.
class ShopDetailsScreen extends ConsumerWidget {
  const ShopDetailsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopByIdProvider(shopId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(shop.valueOrNull?.shopName ?? 'Shop')),
        body: AsyncValueView<Shop?>(
          value: shop,
          onRetry: () => ref.invalidate(shopByIdProvider(shopId)),
          data: (s) {
            if (s == null) {
              return const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Shop not found',
                  message: 'This shop may no longer exist.');
            }
            return Column(
              children: [
                _ShopHeader(shop: s, shopId: shopId),
                Container(
                  color: AppColors.surface,
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Products'),
                      Tab(text: 'Delivery'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ProductsTab(shopId: shopId),
                      _DeliveryTab(shopId: shopId),
                      ShopReviewsList(shopId: shopId),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopHeader extends ConsumerWidget {
  const _ShopHeader({required this.shop, required this.shopId});
  final Shop shop;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(shopMarketItemsProvider(shopId)).valueOrNull?.length;
    final location =
        [shop.barangay, shop.city, shop.province].where((e) => e.isNotEmpty).join(', ');

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: NetworkImageBox(
                url: shop.logoUrl,
                fallbackIcon: Icons.storefront,
                borderRadius: BorderRadius.circular(34)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.shopName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                RatingSummary(
                    rating: shop.rating,
                    reviewCount: shop.totalReviews,
                    size: 15),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(location,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary))),
                  ]),
                ],
                if (shop.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(shop.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
                if (count != null) ...[
                  const SizedBox(height: 6),
                  Text('$count products',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(selectedLocationProvider);
    return AsyncValueView<List<MarketItem>>(
      value: ref.watch(shopMarketItemsProvider(shopId)),
      onRetry: () => ref.invalidate(shopMarketItemsProvider(shopId)),
      isEmpty: (l) => l.isEmpty,
      empty: const EmptyState(
          title: 'No frozen products found.',
          message: "This shop hasn't listed any products yet."),
      data: (items) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: ProductCard.gridDelegate,
        itemCount: items.length,
        itemBuilder: (_, i) => MarketProductCard(item: items[i], location: loc),
      ),
    );
  }
}

class _DeliveryTab extends ConsumerWidget {
  const _DeliveryTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(selectedLocationProvider);
    return AsyncValueView<List<DeliveryArea>>(
      value: ref.watch(shopAreasProvider(shopId)),
      onRetry: () => ref.invalidate(shopAreasProvider(shopId)),
      isEmpty: (l) => l.isEmpty,
      empty: const EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'No delivery areas yet',
          message: "This shop hasn't set up delivery areas."),
      data: (areas) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: areas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = areas[i];
          final yours = loc != null && a.covers(loc);
          return Card(
            child: ListTile(
              leading: Icon(
                  a.isBarangayLevel
                      ? Icons.location_on_outlined
                      : Icons.location_city_outlined,
                  color: AppColors.primary),
              title: Text(a.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(a.coverageLabel),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.peso(a.shippingFee),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  if (yours)
                    const Text('Your area',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
