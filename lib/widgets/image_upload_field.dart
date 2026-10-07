import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/error_mapper.dart';
import '../providers/image_providers.dart';
import '../theme/app_colors.dart';
import 'app_snackbar.dart';
import 'network_image_box.dart';

/// Tap to pick (camera/gallery) -> compress -> upload with progress.
/// Used for product photos, shop logos and profile photos.
/// [onUploaded] receives the final URL (save it to Firestore there).
class ImageUploadField extends ConsumerStatefulWidget {
  const ImageUploadField({
    super.key,
    required this.url,
    required this.onUploaded,
    required this.folder,
    this.circle = false,
    this.size = 100,
    this.aspectRatio = 1.5,
    this.onBusyChanged,
    this.fallbackIcon = Icons.add_a_photo_outlined,
  });

  final String? url;
  final FutureOr<void> Function(String url) onUploaded;
  final String folder; // products | shops | users
  final bool circle;
  final double size; // diameter when circle
  final double aspectRatio; // when not circle
  final ValueChanged<bool>? onBusyChanged;
  final IconData fallbackIcon;

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  File? _local;
  double _progress = 0;
  bool _uploading = false;

  @override
  void didUpdateWidget(covariant ImageUploadField old) {
    super.didUpdateWidget(old);
    // New URL arrived from the parent -> drop the local preview.
    if (old.url != widget.url && !_uploading) _local = null;
  }

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    final service = ref.read(imageServiceProvider);
    try {
      final file = await service.pick(source);
      if (file == null || !mounted) return;
      setState(() {
        _local = file;
        _progress = 0;
        _uploading = true;
      });
      widget.onBusyChanged?.call(true);

      final bytes = await service.compress(file);
      final url = await service.upload(bytes,
          folder: widget.folder,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          });
      await widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        setState(() => _local = null);
        AppSnackbar.error(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (_local != null)
          Image.file(_local!, fit: BoxFit.cover)
        else
          NetworkImageBox(url: widget.url, fallbackIcon: widget.fallbackIcon),
        if (_uploading)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      strokeWidth: 3,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text('${(_progress * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );

    final Widget box = widget.circle
        ? SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipOval(child: content))
        : AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16), child: content));

    return GestureDetector(
      onTap: _uploading ? null : _choose,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          box,
          if (!_uploading)
            Positioned(
              right: widget.circle ? 0 : 10,
              bottom: widget.circle ? 0 : 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera,
                    size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
