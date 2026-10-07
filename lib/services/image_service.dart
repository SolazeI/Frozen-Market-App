import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/cloudinary_config.dart';
import '../core/errors/app_exception.dart';

/// Pick -> compress -> upload to Cloudinary (unsigned preset) with progress.
/// Raw photos are never stored in Firestore; only the returned URL is.
class ImageService {
  final ImagePicker _picker = ImagePicker();

  static const _maxUploadBytes = 5 * 1024 * 1024;

  /// Returns null if the user cancels.
  Future<File?> pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
          source: source, maxWidth: 2000, maxHeight: 2000);
      return x == null ? null : File(x.path);
    } on PlatformException {
      throw const AppException(
          'Could not access your camera or photos. Check app permissions.');
    }
  }

  /// Resizes to a reasonable size and re-encodes as JPEG (quality 80).
  Future<Uint8List> compress(File file) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (bytes == null) {
      throw const AppException("We couldn't process that image. Try another one.");
    }
    if (bytes.length > _maxUploadBytes) {
      throw const AppException('That image is too large. Choose a smaller one.');
    }
    return bytes;
  }

  /// Uploads and returns the secure image URL. [onProgress] gets 0.0 - 1.0.
  Future<String> upload(
    Uint8List bytes, {
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const AppException(
          'Image uploads are not set up yet. Add your Cloudinary settings.');
    }

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');

    final multipart = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'frostmart/$folder'
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: 'image.jpg'));

    final total = multipart.contentLength;
    final body = multipart.finalize(); // also sets the multipart content-type
    final request = http.StreamedRequest('POST', uri)
      ..headers.addAll(multipart.headers)
      ..contentLength = total;

    var sent = 0;
    body.listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        onProgress?.call((sent / total).clamp(0.0, 1.0));
      },
      onDone: request.sink.close,
      onError: request.sink.addError,
    );

    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw const AppException('Image upload failed. Please try again.');
      }
      final url = (jsonDecode(response.body) as Map)['secure_url'] as String?;
      if (url == null) {
        throw const AppException('Image upload failed. Please try again.');
      }
      onProgress?.call(1);
      return url;
    } on SocketException {
      throw const AppException(
          'No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw const AppException('The upload timed out. Please try again.');
    } on http.ClientException {
      throw const AppException('Image upload failed. Please try again.');
    }
  }
}
