import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/firestore_utils.dart';
import '../models/product.dart';

/// Firestore access for products/{productId}. Ownership is enforced by
/// Firestore rules (sellerId must equal the signed-in uid).
class ProductRepository {
  ProductRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Collections.products);

  String newId() => _col.doc().id;

  /// Live list of a seller's products, newest first. Sorted client-side so no
  /// composite index is needed.
  Stream<List<Product>> watchSellerProducts(String sellerId) => _col
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map((d) => Product.fromMap(d.data())).toList();
        final now = DateTime.now();
        list.sort((a, b) =>
            (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  Stream<Product?> watchProduct(String productId) =>
      _col.doc(productId).snapshots().map((s) =>
          (s.exists && s.data() != null) ? Product.fromMap(s.data()!) : null);

  Future<void> create(Product p) => _col.doc(p.productId).set(p.toCreateMap());

  Future<void> update(
    String productId, {
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    required String? imageUrl,
    required bool isAvailable,
  }) =>
      _col.doc(productId).update({
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setAvailability(String productId, bool isAvailable) =>
      _col.doc(productId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Atomically adds [delta] (may be negative) to stock inside a transaction.
  /// Throws 'Insufficient stock.' instead of ever going below zero.
  Future<int> adjustStock(String productId, int delta) =>
      _db.runTransaction((tx) async {
        final ref = _col.doc(productId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const AppException('This product no longer exists.');
        }
        final next = toInt(snap.data()!['stock']) + delta;
        if (next < 0) throw const AppException('Insufficient stock.');
        tx.update(ref, {
          'stock': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return next;
      });

  Future<void> delete(String productId) => _col.doc(productId).delete();
}
