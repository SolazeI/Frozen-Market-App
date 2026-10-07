import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../models/registration_data.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

// ---- Infrastructure -------------------------------------------------------
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final googleSignInProvider = Provider((ref) => GoogleSignIn());

final authServiceProvider = Provider((ref) => AuthService(
    ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider)));
final userRepositoryProvider =
    Provider((ref) => UserRepository(ref.watch(firestoreProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepository(
    ref.watch(authServiceProvider), ref.watch(userRepositoryProvider)));

// ---- State ----------------------------------------------------------------
/// Firebase auth session (null = logged out).
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authStateChanges);

/// Live Firestore profile of the signed-in user (null = no profile yet).
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});

/// True while register/Google flows run, so the router doesn't redirect to
/// Complete Profile in the moment between auth creation and profile write.
final authBusyProvider = StateProvider<bool>((ref) => false);

/// Keeps the splash visible for a minimum time.
final splashDelayProvider = FutureProvider<void>(
    (ref) => Future.delayed(const Duration(milliseconds: 1800)));

// ---- Controller -----------------------------------------------------------
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Runs [action], exposing loading/error via state. Returns true on success.
  Future<bool> _run(Future<void> Function() action,
      {bool holdRouter = false}) async {
    state = const AsyncLoading();
    if (holdRouter) ref.read(authBusyProvider.notifier).state = true;
    state = await AsyncValue.guard(action);
    if (holdRouter) ref.read(authBusyProvider.notifier).state = false;
    return !state.hasError;
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repo.login(email, password));

  Future<bool> loginWithGoogle() => _run(_repo.loginWithGoogle);

  Future<bool> register(RegistrationData data, String password) =>
      _run(() => _repo.register(data, password), holdRouter: true);

  Future<bool> completeProfile(RegistrationData data) =>
      _run(() => _repo.completeProfile(data), holdRouter: true);

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<bool> logout() => _run(_repo.logout);
}
