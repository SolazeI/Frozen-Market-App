import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/registration_data.dart';
import '../models/shop.dart';
import '../services/auth_service.dart';
import 'user_repository.dart';

/// Orchestrates auth + profile creation. Screens never touch Firebase directly.
class AuthRepository {
  AuthRepository(this._auth, this._users);
  final AuthService _auth;
  final UserRepository _users;

  /// Email/password registration. If the profile write fails the new auth
  /// account is deleted so the user can retry cleanly.
  Future<void> register(RegistrationData data, String password) async {
    final user = await _auth.signUp(
        email: data.email, password: password, displayName: data.fullName);
    try {
      await _saveProfile(user.uid, data);
    } catch (_) {
      await _auth.deleteCurrentUser();
      rethrow;
    }
  }

  Future<void> login(String email, String password) =>
      _auth.signIn(email, password);

  /// Signs in with Google. If the account has no profile yet the router sends
  /// the user to Complete Profile to choose a role.
  Future<void> loginWithGoogle() => _auth.signInWithGoogle();

  /// Creates the profile for an already-authenticated user (Google flow).
  Future<void> completeProfile(RegistrationData data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Your session expired. Please log in again.');
    }
    await _saveProfile(user.uid, data);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an email is registered.
      if (e.code != 'user-not-found') rethrow;
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> _saveProfile(String uid, RegistrationData d) async {
    final user = AppUser(
      uid: uid,
      role: d.role,
      fullName: d.fullName,
      email: d.email,
      phone: d.phone,
      address: d.address,
      location: d.location,
    );
    if (d.role == UserRoles.seller) {
      final shop = Shop(
        shopId: uid, // one shop per seller; shopId == sellerId
        sellerId: uid,
        shopName: d.shopName ?? '',
        description: d.shopDescription ?? '',
        address: d.address,
        location: d.location,
      );
      await _users.createSeller(user, shop);
    } else {
      await _users.createCustomer(user);
    }
  }
}
