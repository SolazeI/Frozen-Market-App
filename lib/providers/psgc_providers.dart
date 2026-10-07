import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/psgc_place.dart';
import '../services/psgc_service.dart';

final psgcServiceProvider = Provider((ref) => PsgcService());

final regionsProvider = FutureProvider<List<PsgcPlace>>(
    (ref) => ref.watch(psgcServiceProvider).regions());

/// Provinces of a region. Empty for NCR.
final provincesProvider = FutureProvider.family<List<PsgcPlace>, String>(
    (ref, regionCode) =>
        ref.watch(psgcServiceProvider).provinces(regionCode));

/// Cities/municipalities for (regionCode, provinceCode?). When the province is
/// null (region without provinces) cities are loaded straight from the region.
final citiesProvider =
    FutureProvider.family<List<PsgcPlace>, (String, String?)>((ref, key) {
  final (regionCode, provinceCode) = key;
  final svc = ref.watch(psgcServiceProvider);
  return provinceCode == null
      ? svc.citiesByRegion(regionCode)
      : svc.citiesByProvince(provinceCode);
});

final barangaysProvider = FutureProvider.family<List<PsgcPlace>, String>(
    (ref, cityCode) => ref.watch(psgcServiceProvider).barangays(cityCode));
