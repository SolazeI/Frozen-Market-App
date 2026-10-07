class CloudinaryConfig {
  CloudinaryConfig._();

  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'iiqjmstu', // Updated to match your Cloudinary account
  );

  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'Frozen_Foods', // Matches your Unsigned preset
  );

  static bool get isConfigured =>
      cloudName.isNotEmpty &&
      uploadPreset.isNotEmpty &&
      cloudName != 'PASTE_YOUR_CLOUD_NAME_HERE';
}