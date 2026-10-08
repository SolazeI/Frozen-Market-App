import '../../models/delivery_area.dart';
import '../../models/psgc_location.dart';

/// Location matching + shipping fee logic (business rules 1-5).
/// Matching uses PSGC codes, never GPS. A barangay-level area is more specific
/// than a city-level one, so it wins when both cover the customer.
class DeliveryMatcher {
  DeliveryMatcher._();

  static DeliveryArea? bestMatch(
      Iterable<DeliveryArea> areas, PsgcLocation customer) {
    DeliveryArea? best;
    for (final a in areas) {
      if (!a.isActive || !a.covers(customer)) continue;
      if (best == null || (a.isBarangayLevel && !best.isBarangayLevel)) {
        best = a;
      }
    }
    return best;
  }

  /// Best covering area for each shop, keyed by shopId. Shipping fees are
  /// therefore seller-specific and location-specific.
  static Map<String, DeliveryArea> bestPerShop(
      Iterable<DeliveryArea> areas, PsgcLocation customer) {
    final result = <String, DeliveryArea>{};
    for (final a in areas) {
      if (!a.isActive || !a.covers(customer)) continue;
      final current = result[a.shopId];
      if (current == null || (a.isBarangayLevel && !current.isBarangayLevel)) {
        result[a.shopId] = a;
      }
    }
    return result;
  }
}
