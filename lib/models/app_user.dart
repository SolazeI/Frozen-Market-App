import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/firestore_utils.dart';
import 'psgc_location.dart';

/// users/{uid}. [role] is immutable after creation (enforced by Firestore rules).
/// [location] is the home address (PSGC); [selectedLocation] is where the
/// customer currently wants deliveries (may differ from home).
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.location = PsgcLocation.empty,
    this.selectedLocation,
    this.createdAt,
    this.profileImage,
  });

  final String uid;
  final String role;
  final String fullName;
  final String email;
  final String phone;
  final String address; // street / house number
  final PsgcLocation location;
  final PsgcLocation? selectedLocation;
  final DateTime? createdAt;
  final String? profileImage;

  String get region => location.region;
  String get province => location.province;
  String get city => location.city;
  String get barangay => location.barangay;

  bool get isSeller => role == UserRoles.seller;
  bool get isCustomer => role == UserRoles.customer;

  factory AppUser.fromMap(Map<String, dynamic> m) {
    final sel = m['selectedLocation'];
    return AppUser(
      uid: m['uid'] as String? ?? '',
      role: m['role'] as String? ?? UserRoles.customer,
      fullName: m['fullName'] as String? ?? '',
      email: m['email'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      address: m['address'] as String? ?? '',
      location: PsgcLocation.fromMap(m),
      selectedLocation:
          sel is Map ? PsgcLocation.fromMap(Map<String, dynamic>.from(sel)) : null,
      createdAt: toDate(m['createdAt']),
      profileImage: m['profileImage'] as String?,
    );
  }

  /// Full document for the initial write only (sets server timestamp).
  Map<String, dynamic> toCreateMap() => {
        'uid': uid,
        'role': role,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        ...location.toMap(),
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
