import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/psgc_location.dart';
import '../models/seller_stats.dart';
import '../models/shop.dart';
import '../repositories/shop_repository.dart';
import 'auth_providers.dart';
import 'order_providers.dart';
import 'product_providers.dart';
import 'user_providers.dart';

final shopRepositoryProvider =
    Provider((ref) => ShopRepository(ref.watch(firestoreProvider)));

/// The signed-in seller's own shop (live). Null for customers / logged out.
final myShopProvider = StreamProvider<Shop?>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isSeller) ? u.uid : null));
  if (uid == null) return Stream.value(null);
  return ref.watch(shopRepositoryProvider).watchShop(uid);
});

/// Dashboard numbers. Rating and sales come from the shop document and the
/// product count from the seller's products. pendingOrders is wired in
/// Phase 12 (orders) and reads 0 until then.
final sellerStatsProvider = Provider<AsyncValue<SellerStats>>((ref) {
  final productCount = ref.watch(myProductsProvider).valueOrNull?.length ?? 0;
  // Sales come from the seller's own delivered orders, so they cannot be
  // faked by editing the shop document.
  final orders = ref.watch(sellerOrdersProvider).valueOrNull ?? const <CustomerOrder>[];
  final pendingOrders =
      orders.where((o) => o.status == OrderStatus.pending).length;
  final totalSales = orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold<double>(0, (s, o) => s + o.total);
  return ref.watch(myShopProvider).whenData((shop) => SellerStats(
        totalProducts: productCount,
        pendingOrders: pendingOrders,
        totalSales: totalSales,
        rating: shop?.rating ?? 0,
        totalReviews: shop?.totalReviews ?? 0,
      ));
});

final shopControllerProvider =
    AsyncNotifierProvider<ShopController, void>(ShopController.new);

class ShopController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success; errors are exposed through [state].
  Future<bool> updateShop({
    required String shopName,
    required String description,
    required String address,
    required PsgcLocation location,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isSeller) {
      state = AsyncError(
          const AppException("You don't have permission to perform this action."),
          StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(shopRepositoryProvider).updateShop(user.uid,
            shopName: shopName,
            description: description,
            address: address,
            location: location));
    return !state.hasError;
  }

  /// Saves a freshly uploaded logo URL on the seller's own shop.
  Future<bool> updateLogo(String url) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isSeller) {
      state = AsyncError(
          const AppException("You don't have permission to perform this action."),
          StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(shopRepositoryProvider).updateLogo(user.uid, url));
    return !state.hasError;
  }
}
