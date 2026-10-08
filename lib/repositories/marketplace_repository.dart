import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/product.dart';
import '../models/shop.dart';

/// Read-only customer queries for shops and products.
class MarketplaceRepository {
  MarketplaceRepository(this._db);
  final FirebaseFirestore _db;

  // Firestore 'whereIn' accepts at most 10 values per query.
  Iterable<List<String>> _chunks(Iterable<String> ids) sync* {
    final list = ids.toSet().toList();
    for (var i = 0; i < list.length; i += 10) {
      yield list.sublist(i, min(i + 10, list.length));
    }
  }

  Future<List<Shop>> getShops(Iterable<String> shopIds) async {
    final out = <Shop>[];
    for (final chunk in _chunks(shopIds)) {
      final snap = await _db
          .collection(Collections.shops)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      out.addAll(snap.docs.map((d) => Shop.fromMap(d.data())));
    }
    return out;
  }

  /// Products that sellers have listed (isAvailable) for the given shops.
  Future<List<Product>> getProductsByShops(Iterable<String> shopIds) async {
    final out = <Product>[];
    for (final chunk in _chunks(shopIds)) {
      final snap = await _db
          .collection(Collections.products)
          .where('shopId', whereIn: chunk)
          .get();
      out.addAll(snap.docs
          .map((d) => Product.fromMap(d.data()))
          .where((p) => p.isAvailable));
    }
    return out;
  }

  Future<List<Product>> getShopProducts(String shopId) =>
      getProductsByShops([shopId]);
}
