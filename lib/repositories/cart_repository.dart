import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/firestore_utils.dart';
import '../models/cart_item.dart';

/// Cart lives in users/{uid}/cart so it follows the customer across devices.
class CartRepository {
  CartRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _cart(String uid) =>
      _db.collection(Collections.users).doc(uid).collection('cart');

  Stream<List<CartItem>> watchCart(String uid) =>
      _cart(uid).snapshots().map((s) {
        final list = s.docs.map((d) => CartItem.fromMap(d.data())).toList();
        final now = DateTime.now();
        list.sort((a, b) => (a.addedAt ?? now).compareTo(b.addedAt ?? now));
        return list;
      });

  /// Adds [qty] (or increases an existing line) without exceeding [maxQty].
  Future<void> addOrIncrement(
    String uid, {
    required String productId,
    required String shopId,
    required int qty,
    required int maxQty,
  }) =>
      _db.runTransaction((tx) async {
        final ref = _cart(uid).doc(productId);
        final snap = await tx.get(ref);
        final current = snap.exists ? toInt(snap.data()!['quantity']) : 0;
        final next = current + qty;
        if (next > maxQty) {
          throw AppException(current > 0
              ? 'You already have $current in your cart. Only $maxQty available.'
              : 'Only $maxQty available.');
        }
        if (snap.exists) {
          tx.update(ref, {'quantity': next, 'selected': true});
        } else {
          tx.set(
              ref,
              CartItem(productId: productId, shopId: shopId, quantity: qty)
                  .toCreateMap());
        }
      });

  Future<void> setQuantity(String uid, String productId, int qty) =>
      _cart(uid).doc(productId).update({'quantity': qty});

  Future<void> setSelected(String uid, String productId, bool selected) =>
      _cart(uid).doc(productId).update({'selected': selected});

  Future<void> setManySelected(
      String uid, Iterable<String> productIds, bool selected) {
    final batch = _db.batch();
    for (final id in productIds) {
      batch.update(_cart(uid).doc(id), {'selected': selected});
    }
    return batch.commit();
  }

  Future<void> remove(String uid, String productId) =>
      _cart(uid).doc(productId).delete();
}
