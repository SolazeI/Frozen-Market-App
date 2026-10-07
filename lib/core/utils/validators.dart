/// Reusable form validators. Each returns an error string or null if valid.
/// Client-side only; Firestore rules enforce the same constraints server-side.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^(09|\+639)\d{9}$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (v) {
        if (v == null || v.isEmpty) return 'Confirm your password';
        if (v != original()) return 'Passwords do not match';
        return null;
      };

  /// Philippine mobile: 09XXXXXXXXX or +639XXXXXXXXX.
  static String? phone(String? v, {bool isRequired = false}) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (s.isEmpty) return isRequired ? 'Phone number is required' : null;
    if (!_phone.hasMatch(s)) return 'Use format 09XXXXXXXXX';
    return null;
  }

  static String? Function(String?) lengthBetween(
          String field, int min, int max) =>
      (v) {
        final s = v?.trim() ?? '';
        if (s.isEmpty) return '$field is required';
        if (s.length < min) return '$field must be at least $min characters';
        if (s.length > max) return '$field must be at most $max characters';
        return null;
      };

  static final shopName = lengthBetween('Shop name', 3, 60);
  static final productName = lengthBetween('Product name', 3, 80);
  static final personName = lengthBetween('Name', 2, 40);

  static String? address(String? v) => lengthBetween('Address', 5, 150)(v);

  /// Price must be a number > 0.
  static String? price(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a valid price';
    if (n <= 0) return 'Price must be greater than 0';
    if (n > 1000000) return 'Price is too high';
    return null;
  }

  /// Quantity/stock must be a whole number >= 0.
  static String? quantity(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    if (n < 0) return 'Quantity cannot be negative';
    if (n > 100000) return 'Quantity is too high';
    return null;
  }

  /// Shipping fee must be a number >= 0.
  static String? shippingFee(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a valid shipping fee';
    if (n < 0) return 'Shipping fee cannot be negative';
    if (n > 10000) return 'Shipping fee is too high';
    return null;
  }
}
