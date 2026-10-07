import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/psgc_location.dart';
import '../../models/registration_data.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'auth_ui.dart';

/// Register screen. With [completeProfile] = true it is reused after Google
/// sign-in: email/password are hidden and the user only picks a role + details.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.completeProfile = false});
  final bool completeProfile;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = UserRoles.customer;

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  PsgcLocation _location = PsgcLocation.empty;
  final _shopName = TextEditingController();
  final _shopDesc = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.completeProfile) {
      final user = ref.read(firebaseAuthProvider).currentUser;
      _email.text = user?.email ?? '';
      final parts = (user?.displayName ?? '').trim().split(' ');
      if (parts.isNotEmpty) _first.text = parts.first;
      if (parts.length > 1) _last.text = parts.sublist(1).join(' ');
    }
  }

  @override
  void dispose() {
    for (final c in [
      _first, _last, _email, _password, _confirm, _phone, _address,
      _shopName, _shopDesc
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isSeller => _role == UserRoles.seller;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final data = RegistrationData(
      role: _role,
      fullName: '${_first.text.trim()} ${_last.text.trim()}'.trim(),
      email: _email.text.trim(),
      phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
      address: _address.text.trim(),
      location: _location,
      shopName: _isSeller ? _shopName.text.trim() : null,
      shopDescription: _isSeller ? _shopDesc.text.trim() : null,
    );

    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = widget.completeProfile
        ? await ctrl.completeProfile(data)
        : await ctrl.register(data, _password.text);
    if (ok && mounted) {
      AppSnackbar.success(context, 'Welcome to FrostMart!');
    }
  }

  @override
  Widget build(BuildContext context) {
    listenForAuthErrors(context, ref);
    final loading = ref.watch(authControllerProvider).isLoading;
    const gap = SizedBox(height: 14);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.completeProfile ? 'Complete your profile' : 'Register'),
        automaticallyImplyLeading: !widget.completeProfile,
        actions: [
          if (widget.completeProfile)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: loading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('I am registering as:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                backgroundColor: AppColors.surface,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: UserRoles.customer,
                    label: Text('Customer'),
                    icon: Icon(Icons.shopping_bag_outlined)),
                ButtonSegment(
                    value: UserRoles.seller,
                    label: Text('Seller'),
                    icon: Icon(Icons.storefront_outlined)),
              ],
              selected: {_role},
              onSelectionChanged:
                  loading ? null : (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: FrostTextField(
                        label: 'First name',
                        controller: _first,
                        validator: Validators.personName)),
                const SizedBox(width: 12),
                Expanded(
                    child: FrostTextField(
                        label: 'Last name',
                        controller: _last,
                        validator: Validators.personName)),
              ],
            ),
            gap,
            FrostTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              enabled: !widget.completeProfile,
              validator: Validators.email,
            ),
            if (!widget.completeProfile) ...[
              gap,
              FrostTextField(
                label: 'Password',
                controller: _password,
                obscureText: true,
                validator: Validators.password,
              ),
              gap,
              FrostTextField(
                label: 'Confirm password',
                controller: _confirm,
                obscureText: true,
                validator: Validators.confirmPassword(() => _password.text),
              ),
            ],
            gap,
            FrostTextField(
              label: 'Phone (optional)',
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
            if (_isSeller) ...[
              const SizedBox(height: 24),
              Text('Shop details',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FrostTextField(
                  label: 'Shop name',
                  controller: _shopName,
                  validator: Validators.shopName),
              gap,
              FrostTextField(
                label: 'Shop description',
                controller: _shopDesc,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                validator: Validators.lengthBetween('Description', 10, 300),
              ),
            ],
            const SizedBox(height: 28),
            FrostButton(
              label: widget.completeProfile ? 'Continue' : 'Create account',
              isLoading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
