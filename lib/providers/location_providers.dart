import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/psgc_location.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

/// The customer's active delivery location (stored on their profile so it
/// follows them across devices). Falls back to the home address.
/// Phase 9 uses this to filter products by seller delivery areas.
final selectedLocationProvider = Provider<PsgcLocation?>((ref) {
  final u = ref.watch(currentUserProvider);
  if (u == null) return null;
  final selected = u.selectedLocation;
  if (selected != null && selected.isComplete) return selected;
  return u.location.isComplete ? u.location : null;
});

final locationControllerProvider =
    AsyncNotifierProvider<LocationController, void>(LocationController.new);

class LocationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> select(PsgcLocation location) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = AsyncError(
          const AppException('Your session expired. Please log in again.'),
          StackTrace.current);
      return false;
    }
    if (!location.isComplete) {
      state = AsyncError(
          const AppException('Please choose your region, city and barangay.'),
          StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(userRepositoryProvider)
        .updateSelectedLocation(uid, location));
    return !state.hasError;
  }
}
