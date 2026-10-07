import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/psgc_location.dart';
import 'auth_providers.dart';

/// The signed-in user's profile (null while loading / logged out).
/// Screens behind the router guard can rely on this being non-null.
final currentUserProvider = Provider<AppUser?>(
    (ref) => ref.watch(userProfileProvider).valueOrNull);

final userRoleProvider =
    Provider<String?>((ref) => ref.watch(currentUserProvider)?.role);

final isSellerProvider =
    Provider<bool>((ref) => ref.watch(userRoleProvider) == UserRoles.seller);

final isCustomerProvider =
    Provider<bool>((ref) => ref.watch(userRoleProvider) == UserRoles.customer);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success; errors are exposed through [state].
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required PsgcLocation location,
  }) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = AsyncError(
          const AppException('Your session expired. Please log in again.'),
          StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(userRepositoryProvider).updateProfile(uid,
            fullName: fullName,
            phone: phone,
            address: address,
            location: location));
    return !state.hasError;
  }

  /// Saves a freshly uploaded profile photo URL.
  Future<bool> updateImage(String url) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = AsyncError(
          const AppException('Your session expired. Please log in again.'),
          StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(userRepositoryProvider).updateProfileImage(uid, url));
    return !state.hasError;
  }
}
