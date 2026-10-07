import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../models/psgc_location.dart';
import '../../models/shop.dart';
import '../../providers/shop_providers.dart';
import '../../widgets/widgets.dart';

class EditShopScreen extends ConsumerWidget {
  const EditShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit shop')),
      body: AsyncValueView<Shop?>(
        value: ref.watch(myShopProvider),
        onRetry: () => ref.invalidate(myShopProvider),
        data: (shop) => shop == null
            ? const ErrorState(
                title: 'Shop not found',
                message: "We couldn't find your shop.")
            : _EditShopForm(shop: shop),
      ),
    );
  }
}

class _EditShopForm extends ConsumerStatefulWidget {
  const _EditShopForm({required this.shop});
  final Shop shop;
  @override
  ConsumerState<_EditShopForm> createState() => _EditShopFormState();
}

class _EditShopFormState extends ConsumerState<_EditShopForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.shop.shopName);
  late final _desc = TextEditingController(text: widget.shop.description);
  late final _address = TextEditingController(text: widget.shop.address);
  late PsgcLocation _location = widget.shop.location;

  @override
  void dispose() {
    for (final c in [_name, _desc, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(shopControllerProvider.notifier).updateShop(
          shopName: _name.text.trim(),
          description: _desc.text.trim(),
          address: _address.text.trim(),
          location: _location,
        );
    if (ok && mounted) {
      AppSnackbar.success(context, 'Shop updated');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(shopControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final loading = ref.watch(shopControllerProvider).isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ImageUploadField(
              url: widget.shop.logoUrl,
              circle: true,
              size: 110,
              folder: 'shops',
              fallbackIcon: Icons.storefront,
              onUploaded: (url) async {
                await ref.read(shopControllerProvider.notifier).updateLogo(url);
              },
            ),
          ),
          const SizedBox(height: 20),
          FrostTextField(
              label: 'Shop name',
              controller: _name,
              validator: Validators.shopName),
          const SizedBox(height: 14),
          FrostTextField(
            label: 'Shop description',
            controller: _desc,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            validator: Validators.lengthBetween('Description', 10, 300),
          ),
          const SizedBox(height: 20),
          Text('Shop location',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
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
    );
  }
}
