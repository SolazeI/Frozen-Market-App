import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/psgc_location.dart';
import '../models/shop.dart';

/// Firestore access for shops/{shopId}. Sellers may only edit their own shop
/// (shopId == sellerId uid); Firestore rules enforce this server-side.
class ShopRepository {
  ShopRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection(Collections.shops);

  Stream<Shop?> watchShop(String shopId) => _shops.doc(shopId).snapshots().map(
      (s) => (s.exists && s.data() != null) ? Shop.fromMap(s.data()!) : null);

  Future<Shop?> getShop(String shopId) async {
    final s = await _shops.doc(shopId).get();
    return (s.exists && s.data() != null) ? Shop.fromMap(s.data()!) : null;
  }

  /// Updates the editable shop details only. Rating, review count and sales
  /// are never written from this screen.
  Future<void> updateShop(
    String shopId, {
    required String shopName,
    required String description,
    required String address,
    required PsgcLocation location,
  }) =>
      _shops.doc(shopId).update({
        'shopName': shopName,
        'description': description,
        'address': address,
        ...location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateLogo(String shopId, String url) =>
      _shops.doc(shopId).update({
        'logoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
