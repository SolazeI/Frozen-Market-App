import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/delivery_area.dart';
import '../models/psgc_location.dart';
import '../repositories/delivery_area_repository.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

final deliveryAreaRepositoryProvider =
    Provider((ref) => DeliveryAreaRepository(ref.watch(firestoreProvider)));

/// The signed-in seller's delivery areas (live).
final myDeliveryAreasProvider = StreamProvider<List<DeliveryArea>>((ref) {
  final uid = ref.watch(currentUserProvider
      .select((u) => (u != null && u.isSeller) ? u.uid : null));
  if (uid == null) return Stream.value(const <DeliveryArea>[]);
  return ref.watch(deliveryAreaRepositoryProvider).watchShopAreas(uid);
});

final deliveryAreaControllerProvider =
    AsyncNotifierProvider<DeliveryAreaController, void>(
        DeliveryAreaController.new);

class DeliveryAreaController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  DeliveryAreaRepository get _repo => ref.read(deliveryAreaRepositoryProvider);

  String _sellerUid() {
    final u = ref.read(currentUserProvider);
    if (u == null || !u.isSeller) {
      throw const AppException("You don't have permission to perform this action.");
    }
    return u.uid;
  }

  void _validateFee(double fee) {
    if (fee.isNaN || fee < 0) {
      throw const AppException('Shipping fee cannot be negative.');
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> addArea(PsgcLocation location, double fee) => _run(() async {
        final uid = _sellerUid();
        if (!location.hasCity) {
          throw const AppException('Please choose a city or municipality.');
        }
        _validateFee(fee);
        final id = DeliveryArea.buildId(uid, location);
        final existing = ref.read(myDeliveryAreasProvider).valueOrNull ?? [];
        if (existing.any((a) => a.areaId == id)) {
          throw const AppException('You already have this delivery area.');
        }
        await _repo.create(DeliveryArea(
            areaId: id, shopId: uid, location: location, shippingFee: fee));
      });

  Future<bool> saveChanges(String areaId,
          {required double fee, required bool isActive}) =>
      _run(() async {
        _sellerUid();
        _validateFee(fee);
        await _repo.update(areaId, shippingFee: fee, isActive: isActive);
      });

  Future<bool> setActive(String areaId, bool value) => _run(() {
        _sellerUid();
        return _repo.setActive(areaId, value);
      });

  Future<bool> deleteArea(String areaId) => _run(() {
        _sellerUid();
        return _repo.delete(areaId);
      });
}
