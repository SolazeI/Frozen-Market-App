import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/delivery_matcher.dart';
import '../models/cart_item.dart';
import '../models/cart_view.dart';
import '../models/delivery_area.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';
import 'auth_providers.dart';
import 'delivery_providers.dart';
import 'location_providers.dart';
import 'marketplace_providers.dart';
import 'user_providers.dart';

final cartRepositoryProvider =
    Provider((ref) => CartRepository(ref.watch(firestoreProvider)));

/// The customer's cart lines (live).
final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isCustomer) ? u.uid : null));
  if (uid == null) return Stream.value(const <CartItem>[]);
  return ref.watch(cartRepositoryProvider).watchCart(uid);
});

/// Number of lines, for the cart badge.
final cartCountProvider = Provider<int>(
    (ref) => ref.watch(cartItemsProvider).valueOrNull?.length ?? 0);

/// Fetches products, shops and delivery quotes for a set of cart lines.
/// [key] is "productId|shopId,productId|shopId,..." so changing only a
/// quantity does NOT refetch anything.
final cartLookupProvider =
    FutureProvider.autoDispose.family<CartLookup, String>((ref, key) async {
  final pairs = key
      .split(',')
      .where((e) => e.isNotEmpty)
      .map((e) => e.split('|'))
      .toList();
  final productIds = pairs.map((p) => p[0]).toSet();
  final shopIds = pairs.map((p) => p[1]).toSet();

  // Subscribe to quotes synchronously so they refresh when location changes.
  final quoteFutures = {
    for (final id in shopIds) id: ref.watch(deliveryQuoteProvider(id).future)
  };
  final market = ref.watch(marketplaceRepositoryProvider);

  final products = await market.getProductsByIds(productIds);
  final shops = await market.getShops(shopIds);
  final areas = <String, DeliveryArea?>{
    for (final e in quoteFutures.entries) e.key: await e.value,
  };
  return CartLookup(
    products: {for (final p in products) p.productId: p},
    shops: {for (final s in shops) s.shopId: s},
    areas: areas,
  );
});

/// The cart, grouped by seller, with per-seller shipping and totals.
final cartViewProvider = Provider<AsyncValue<CartView>>((ref) {
  final items = ref.watch(cartItemsProvider);
  return items.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (list) {
      if (list.isEmpty) return const AsyncData(CartView.empty);
      final key = (list.map((i) => '${i.productId}|${i.shopId}').toList()
            ..sort())
          .join(',');
      return ref
          .watch(cartLookupProvider(key))
          .whenData((lookup) => CartView.build(list, lookup));
    },
  );
});

/// "Buy now": a one-line checkout that bypasses the cart.
final buyNowViewProvider = FutureProvider.autoDispose
    .family<CartView, (String, String, int)>((ref, args) async {
  final (productId, shopId, qty) = args;
  final quote = ref.watch(deliveryQuoteProvider(shopId).future);
  final market = ref.watch(marketplaceRepositoryProvider);
  final products = await market.getProductsByIds([productId]);
  final shops = await market.getShops([shopId]);
  final area = await quote;
  return CartView.build(
    [CartItem(productId: productId, shopId: shopId, quantity: qty)],
    CartLookup(
      products: {for (final p in products) p.productId: p},
      shops: {for (final s in shops) s.shopId: s},
      areas: {shopId: area},
    ),
  );
});

final cartControllerProvider =
    AsyncNotifierProvider<CartController, void>(CartController.new);

class CartController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  String _customerUid() {
    final u = ref.read(currentUserProvider);
    if (u == null || !u.isCustomer) {
      throw const AppException("You don't have permission to perform this action.");
    }
    return u.uid;
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  /// Rule 1: only products whose seller delivers to the selected location.
  Future<bool> addToCart(Product p, int qty) => _run(() async {
        final uid = _customerUid();
        if (qty < 1) throw const AppException('Quantity must be at least 1.');
        if (!p.isAvailable) {
          throw const AppException('This product is not available.');
        }
        if (!p.inStock) throw const AppException('This product is out of stock.');

        final loc = ref.read(selectedLocationProvider);
        if (loc == null) {
          throw const AppException('Choose your delivery location first.');
        }
        final areas = await ref
            .read(deliveryAreaRepositoryProvider)
            .getActiveShopAreas(p.shopId);
        if (DeliveryMatcher.bestMatch(areas, loc) == null) {
          throw const AppException(
              "This seller doesn't deliver to your location.");
        }
        await _repo.addOrIncrement(uid,
            productId: p.productId,
            shopId: p.shopId,
            qty: qty,
            maxQty: p.stock);
      });

  Future<bool> setQuantity(String productId, int qty, {required int stock}) =>
      _run(() async {
        final uid = _customerUid();
        if (qty < 1) throw const AppException('Quantity must be at least 1.');
        if (qty > stock) throw AppException('Only $stock available.');
        await _repo.setQuantity(uid, productId, qty);
      });

  Future<bool> setSelected(String productId, bool value) => _run(() =>
      _repo.setSelected(_customerUid(), productId, value));

  Future<bool> setGroupSelected(Iterable<String> productIds, bool value) =>
      _run(() => _repo.setManySelected(_customerUid(), productIds, value));

  Future<bool> remove(String productId) =>
      _run(() => _repo.remove(_customerUid(), productId));
}
