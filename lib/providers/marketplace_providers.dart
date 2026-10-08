import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/delivery_matcher.dart';
import '../models/delivery_area.dart';
import '../models/market_item.dart';
import '../models/shop.dart';
import '../repositories/marketplace_repository.dart';
import 'auth_providers.dart';
import 'delivery_providers.dart';
import 'location_providers.dart';
import 'shop_providers.dart';

final marketplaceRepositoryProvider =
    Provider((ref) => MarketplaceRepository(ref.watch(firestoreProvider)));

/// THE location-based discovery feed.
/// 1. active delivery areas in the customer's city
/// 2. keep the ones that cover the customer's barangay (best area per shop)
/// 3. load those shops and their listed products
/// Sellers who don't deliver to the customer never appear (Rule 3).
/// Local and out-of-town sellers both appear, each with their own fee (Rules 2, 4, 5).
final marketFeedProvider =
    FutureProvider.autoDispose<List<MarketItem>>((ref) async {
  final loc = ref.watch(selectedLocationProvider);
  if (loc == null) return const [];

  final areas = await ref
      .watch(deliveryAreaRepositoryProvider)
      .getActiveAreasForCity(loc.cityCode);
  final bestByShop = DeliveryMatcher.bestPerShop(areas, loc);
  if (bestByShop.isEmpty) return const [];

  final market = ref.watch(marketplaceRepositoryProvider);
  final shops = {
    for (final s in await market.getShops(bestByShop.keys)) s.shopId: s
  };
  final products = await market.getProductsByShops(shops.keys);

  return [
    for (final p in products)
      if (shops.containsKey(p.shopId))
        MarketItem(
            product: p, shop: shops[p.shopId]!, area: bestByShop[p.shopId]),
  ];
});

/// Live shop document for the shop page / product details.
final shopByIdProvider = StreamProvider.autoDispose.family<Shop?, String>(
    (ref, shopId) => ref.watch(shopRepositoryProvider).watchShop(shopId));

/// A shop's active delivery areas (public).
final shopAreasProvider =
    FutureProvider.autoDispose.family<List<DeliveryArea>, String>(
        (ref, shopId) => ref
            .watch(deliveryAreaRepositoryProvider)
            .getActiveShopAreas(shopId));

/// The area that covers the customer's location for this shop, or null.
final deliveryQuoteProvider =
    FutureProvider.autoDispose.family<DeliveryArea?, String>((ref, shopId) async {
  final loc = ref.watch(selectedLocationProvider);
  if (loc == null) return null;
  final areas = await ref.watch(shopAreasProvider(shopId).future);
  return DeliveryMatcher.bestMatch(areas, loc);
});

/// All of a shop's listed products, each marked with delivery availability.
final shopMarketItemsProvider = FutureProvider.autoDispose
    .family<List<MarketItem>, String>((ref, shopId) async {
  final shop = await ref.watch(shopRepositoryProvider).getShop(shopId);
  if (shop == null) return const [];
  final area = await ref.watch(deliveryQuoteProvider(shopId).future);
  final products =
      await ref.watch(marketplaceRepositoryProvider).getShopProducts(shopId);
  return [for (final p in products) MarketItem(product: p, shop: shop, area: area)];
});
