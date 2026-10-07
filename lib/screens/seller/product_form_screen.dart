import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../providers/product_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Add (productId == null) or Edit (productId set) a product.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = productId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit product' : 'Add product')),
      body: !isEdit
          ? const _ProductForm()
          : AsyncValueView<Product?>(
              value: ref.watch(productProvider(productId!)),
              onRetry: () => ref.invalidate(productProvider(productId!)),
              data: (p) => p == null
                  ? const ErrorState(
                      title: 'Product not found',
                      message: 'It may have been deleted.')
                  : _ProductForm(product: p),
            ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.product});
  final Product? product;
  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _desc =
      TextEditingController(text: widget.product?.description ?? '');
  late final _price = TextEditingController(
      text: widget.product == null
          ? ''
          : widget.product!.price.toStringAsFixed(2));
  late final _stock =
      TextEditingController(text: widget.product?.stock.toString() ?? '');
  late String? _category = widget.product?.category;
  late bool _available = widget.product?.isAvailable ?? true;
  late String? _imageUrl = widget.product?.imageUrl;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ctrl = ref.read(productControllerProvider.notifier);
    final name = _name.text.trim();
    final desc = _desc.text.trim();
    final price = double.parse(_price.text.trim());
    final stock = int.parse(_stock.text.trim());
    final existing = widget.product;

    final ok = existing == null
        ? await ctrl.create(
            name: name,
            description: desc,
            category: _category!,
            price: price,
            stock: stock,
            imageUrl: _imageUrl,
            isAvailable: _available)
        : await ctrl.updateProduct(existing.productId,
            name: name,
            description: desc,
            category: _category!,
            price: price,
            stock: stock,
            imageUrl: _imageUrl,
            isAvailable: _available);

    if (ok && mounted) {
      AppSnackbar.success(
          context, existing == null ? 'Product added' : 'Product updated');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(productControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final saving = ref.watch(productControllerProvider).isLoading;
    const gap = SizedBox(height: 14);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ImageUploadField(
            url: _imageUrl,
            folder: 'products',
            onBusyChanged: (b) => setState(() => _uploading = b),
            onUploaded: (url) => setState(() => _imageUrl = url),
          ),
          gap,
          FrostTextField(
              label: 'Product name',
              controller: _name,
              validator: Validators.productName),
          gap,
          FormField<String>(
            initialValue: _category,
            validator: (v) => v == null ? 'Choose a category' : null,
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in ProductCategories.list)
                      ChoiceChip(
                        label: Text(c),
                        selected: state.value == c,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                            color: state.value == c
                                ? AppColors.primary
                                : AppColors.border),
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: state.value == c
                                ? Colors.white
                                : AppColors.textPrimary),
                        onSelected: (_) {
                          state.didChange(c);
                          setState(() => _category = c);
                        },
                      ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(state.errorText!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FrostTextField(
                  label: 'Price',
                  prefixText: '₱ ',
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                  ],
                  validator: Validators.price,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FrostTextField(
                  label: 'Quantity',
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.quantity,
                ),
              ),
            ],
          ),
          gap,
          FrostTextField(
            label: 'Description',
            controller: _desc,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            validator: (v) => (v ?? '').length > 1000
                ? 'Keep the description under 1000 characters'
                : null,
          ),
          gap,
          Card(
            child: SwitchListTile(
              title: const Text('Available to customers'),
              subtitle: const Text('Turn off to hide this product'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
          ),
          const SizedBox(height: 24),
          FrostButton(
            label: widget.product == null ? 'Add product' : 'Save changes',
            isLoading: saving,
            onPressed: _uploading ? null : _save,
          ),
          if (_uploading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Waiting for the photo to finish uploading…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
