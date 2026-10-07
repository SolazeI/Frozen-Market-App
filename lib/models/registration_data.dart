import '../core/constants/app_constants.dart';
import 'psgc_location.dart';

/// Form payload shared by Register and Complete-Profile (Google) screens.
class RegistrationData {
  const RegistrationData({
    required this.role,
    required this.fullName,
    required this.email,
    this.phone = '',
    required this.address,
    required this.location,
    this.shopName,
    this.shopDescription,
  });

  final String role;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final PsgcLocation location;
  final String? shopName;
  final String? shopDescription;

  bool get isSeller => role == UserRoles.seller;
}
