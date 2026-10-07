import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/psgc_location.dart';
import '../models/shop.dart';

/// Firestore access for users (and the seller's shop created with them).
class UserRepository {
  UserRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(Collections.users);

  Stream<AppUser?> watchUser(String uid) => _users.doc(uid).snapshots().map(
      (s) => (s.exists && s.data() != null) ? AppUser.fromMap(s.data()!) : null);

  Future<AppUser?> getUser(String uid) async {
    final s = await _users.doc(uid).get();
    return (s.exists && s.data() != null) ? AppUser.fromMap(s.data()!) : null;
  }

  Future<void> createCustomer(AppUser user) =>
      _users.doc(user.uid).set(user.toCreateMap());

  /// Writes the seller profile and their shop atomically.
  Future<void> createSeller(AppUser user, Shop shop) {
    final batch = _db.batch();
    batch.set(_users.doc(user.uid), user.toCreateMap());
    batch.set(_db.collection(Collections.shops).doc(shop.shopId),
        shop.toCreateMap());
    return batch.commit();
  }

  /// Updates only the editable profile fields. role, uid, email and createdAt
  /// can never be changed from the client (also enforced by Firestore rules).
  Future<void> updateProfile(
    String uid, {
    required String fullName,
    required String phone,
    required String address,
    required PsgcLocation location,
  }) =>
      _users.doc(uid).update({
        'fullName': fullName,
        'phone': phone,
        'address': address,
        ...location.toMap(),
      });

  Future<void> updateProfileImage(String uid, String url) =>
      _users.doc(uid).update({'profileImage': url});

  /// The customer's active delivery location.
  Future<void> updateSelectedLocation(String uid, PsgcLocation location) =>
      _users.doc(uid).update({'selectedLocation': location.toMap()});
}
