import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/delivery_area.dart';

/// Firestore access for deliveryAreas. Top-level collection so customer
/// queries by city need no extra index.
class DeliveryAreaRepository {
  DeliveryAreaRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Collections.deliveryAreas);

  List<DeliveryArea> _parse(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map((d) => DeliveryArea.fromMap(d.data())).toList();
    list.sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  // ---- Seller ----
  Stream<List<DeliveryArea>> watchShopAreas(String shopId) =>
      _col.where('shopId', isEqualTo: shopId).snapshots().map(_parse);

  Future<void> create(DeliveryArea a) => _col.doc(a.areaId).set(a.toCreateMap());

  Future<void> update(String areaId,
          {required double shippingFee, required bool isActive}) =>
      _col.doc(areaId).update({
        'shippingFee': shippingFee,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String areaId, bool isActive) =>
      _col.doc(areaId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String areaId) => _col.doc(areaId).delete();

  // ---- Customer ----
  /// Active areas (any shop) in a city, including barangay-level ones.
  Future<List<DeliveryArea>> getActiveAreasForCity(String cityCode) async =>
      _parse(await _col
          .where('cityCode', isEqualTo: cityCode)
          .where('isActive', isEqualTo: true)
          .get());

  Future<List<DeliveryArea>> getActiveShopAreas(String shopId) async =>
      _parse(await _col
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get());
}
