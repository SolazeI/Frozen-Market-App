import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';
import 'psgc_location.dart';

/// deliveryAreas/{areaId}  (top-level collection, shopId == sellerId).
/// An area is city-level (barangay empty = whole city/municipality) or
/// barangay-level. Barangay-level is more specific and wins when both match,
/// e.g. Davao City P50 but Matina P150.
class DeliveryArea {
  const DeliveryArea({
    required this.areaId,
    required this.shopId,
    required this.location,
    required this.shippingFee,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String areaId;
  final String shopId;
  final PsgcLocation location;
  final double shippingFee;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isBarangayLevel => location.hasBarangay;

  String get label =>
      isBarangayLevel ? '${location.barangay}, ${location.city}' : location.city;

  String get coverageLabel =>
      isBarangayLevel ? 'Barangay only' : 'Entire city / municipality';

  /// Does this area cover the customer's location? (Matching uses PSGC codes.)
  bool covers(PsgcLocation c) =>
      c.hasCity &&
      location.cityCode == c.cityCode &&
      (!isBarangayLevel || location.barangayCode == c.barangayCode);

  /// Deterministic id, so the same area can never be added twice.
  static String buildId(String shopId, PsgcLocation l) =>
      '${shopId}_${l.cityCode}_${l.hasBarangay ? l.barangayCode : 'all'}';

  factory DeliveryArea.fromMap(Map<String, dynamic> m) => DeliveryArea(
        areaId: m['areaId'] as String? ?? '',
        shopId: m['shopId'] as String? ?? '',
        location: PsgcLocation.fromMap(m),
        shippingFee: toDouble(m['shippingFee']),
        isActive: m['isActive'] as bool? ?? true,
        createdAt: toDate(m['createdAt']),
        updatedAt: toDate(m['updatedAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'areaId': areaId,
        'shopId': shopId,
        ...location.toMap(),
        'shippingFee': shippingFee,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
