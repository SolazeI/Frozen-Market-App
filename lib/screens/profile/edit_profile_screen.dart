import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../models/psgc_location.dart';
import '../../providers/user_providers.dart';
import '../../widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late PsgcLocation _location;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider);
    _name = TextEditingController(text: u?.fullName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _address = TextEditingController(text: u?.address ?? '');
    _location = u?.location ?? PsgcLocation.empty;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(profileControllerProvider.notifier).updateProfile(
          fullName: _name.text.trim(),
          phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          address: _address.text.trim(),
          location: _location,
        );
    if (ok && mounted) {
      AppSnackbar.success(context, 'Profile updated');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(profileControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final loading = ref.watch(profileControllerProvider).isLoading;
    const gap = SizedBox(height: 14);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ImageUploadField(
                url: ref.watch(currentUserProvider)?.profileImage,
                circle: true,
                size: 100,
                folder: 'users',
                fallbackIcon: Icons.person_outline,
                onUploaded: (url) async {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .updateImage(url);
                },
              ),
            ),
            const SizedBox(height: 20),
            FrostTextField(
                label: 'Full name',
                controller: _name,
                validator: Validators.lengthBetween('Full name', 2, 80)),
            gap,
            FrostTextField(label: 'Email', controller: _email, enabled: false),
            gap,
            FrostTextField(
              label: 'Phone',
              hint: '09XXXXXXXXX',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            gap,
            AddressFields(
              address: _address,
              location: _location,
              onLocationChanged: (l) => setState(() => _location = l),
            ),
            const SizedBox(height: 28),
            FrostButton(
                label: 'Save changes', isLoading: loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
