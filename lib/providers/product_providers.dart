import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

final productRepositoryProvider =
    Provider((ref) => ProductRepository(ref.watch(firestoreProvider)));

/// The signed-in seller's products (live). Empty for non-sellers.
final myProductsProvider = StreamProvider<List<Product>>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isSeller) ? u.uid : null));
  if (uid == null) return Stream.value(const <Product>[]);
  return ref.watch(productRepositoryProvider).watchSellerProducts(uid);
});

final productProvider = StreamProvider.family<Product?, String>(
    (ref, id) => ref.watch(productRepositoryProvider).watchProduct(id));

final productControllerProvider =
    AsyncNotifierProvider<ProductController, void>(ProductController.new);

/// Seller product actions. Business rules (no negative price/stock) live here,
/// not in widgets; Firestore rules repeat them server-side.
class ProductController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  String _sellerUid() {
    final u = ref.read(currentUserProvider);
    if (u == null || !u.isSeller) {
      throw const AppException("You don't have permission to perform this action.");
    }
    return u.uid;
  }

  void _validate(double price, int stock) {
    if (price <= 0) throw const AppException('Price must be greater than 0.');
    if (stock < 0) throw const AppException('Stock cannot be negative.');
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> create({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    required String? imageUrl,
    required bool isAvailable,
  }) =>
      _run(() async {
        final uid = _sellerUid();
        _validate(price, stock);
        await _repo.create(Product(
          productId: _repo.newId(),
          sellerId: uid,
          shopId: uid,
          name: name,
          description: description,
          category: category,
          price: price,
          stock: stock,
          imageUrl: imageUrl,
          isAvailable: isAvailable,
        ));
      });

  Future<bool> updateProduct(
    String productId, {
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    required String? imageUrl,
    required bool isAvailable,
  }) =>
      _run(() async {
        _sellerUid();
        _validate(price, stock);
        await _repo.update(productId,
            name: name,
            description: description,
            category: category,
            price: price,
            stock: stock,
            imageUrl: imageUrl,
            isAvailable: isAvailable);
      });

  Future<bool> setAvailability(String productId, bool value) => _run(() {
        _sellerUid();
        return _repo.setAvailability(productId, value);
      });

  Future<bool> adjustStock(String productId, int delta) => _run(() {
        _sellerUid();
        return _repo.adjustStock(productId, delta);
      });

  Future<bool> delete(String productId) => _run(() {
        _sellerUid();
        return _repo.delete(productId);
      });
}
