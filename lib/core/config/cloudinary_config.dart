/// Cloudinary settings. Either edit the defaults below or pass them at build time:
///   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
///
/// The preset must be an UNSIGNED upload preset (Cloudinary console ->
/// Settings -> Upload -> Upload presets). No API secret ever ships in the app.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'YOUR_CLOUD_NAME');
  static const uploadPreset = String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
      defaultValue: 'YOUR_UNSIGNED_PRESET');

  static bool get isConfigured =>
      !cloudName.startsWith('YOUR_') && !uploadPreset.startsWith('YOUR_');
}
