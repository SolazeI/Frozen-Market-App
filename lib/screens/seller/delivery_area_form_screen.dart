import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../models/delivery_area.dart';
import '../../models/psgc_location.dart';
import '../../providers/delivery_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Add (areaId == null) or edit the fee / status of a delivery area.
/// The location of an existing area is fixed; delete and re-add to change it.
class DeliveryAreaFormScreen extends ConsumerStatefulWidget {
  const DeliveryAreaFormScreen({super.key, this.areaId});
  final String? areaId;

  @override
  ConsumerState<DeliveryAreaFormScreen> createState() =>
      _DeliveryAreaFormScreenState();
}

class _DeliveryAreaFormScreenState
    extends ConsumerState<DeliveryAreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fee = TextEditingController();
  PsgcLocation _location = PsgcLocation.empty;
  bool _active = true;
  DeliveryArea? _existing;
  bool _loaded = false;

  bool get _isEdit => widget.areaId != null;

  @override
  void dispose() {
    _fee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final fee = double.parse(_fee.text.trim());
    final ctrl = ref.read(deliveryAreaControllerProvider.notifier);
    final ok = _isEdit
        ? await ctrl.saveChanges(widget.areaId!, fee: fee, isActive: _active)
        : await ctrl.addArea(_location, fee);
    if (ok && mounted) {
      AppSnackbar.success(
          context, _isEdit ? 'Delivery area updated' : 'Delivery area added');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(deliveryAreaControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final saving = ref.watch(deliveryAreaControllerProvider).isLoading;

    // In edit mode, load the area once from the live list.
    if (_isEdit && !_loaded) {
      final areas = ref.watch(myDeliveryAreasProvider).valueOrNull;
      if (areas == null) {
        return Scaffold(
            appBar: AppBar(title: const Text('Edit delivery area')),
            body: const LoadingView());
      }
      final match = areas.where((a) => a.areaId == widget.areaId);
      if (match.isEmpty) {
        return Scaffold(
            appBar: AppBar(title: const Text('Edit delivery area')),
            body: const ErrorState(
                title: 'Area not found',
                message: 'It may have been deleted.'));
      }
      _existing = match.first;
      _fee.text = _existing!.shippingFee.toStringAsFixed(2);
      _active = _existing!.isActive;
      _loaded = true;
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit delivery area' : 'Add delivery area')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isEdit) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.place_outlined,
                      color: AppColors.primary),
                  title: Text(_existing!.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_existing!.coverageLabel),
                ),
              ),
            ] else ...[
              const Text(
                'Choose a city or municipality. Pick a barangay only if you want a separate fee for it; leave Barangay empty to cover the whole city.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              LocationPicker(
                value: _location,
                requireBarangay: false,
                onChanged: (l) => setState(() => _location = l),
              ),
            ],
            const SizedBox(height: 16),
            FrostTextField(
              label: 'Shipping fee',
              prefixText: '₱ ',
              controller: _fee,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
              ],
              validator: Validators.shippingFee,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 14),
              Card(
                child: SwitchListTile(
                  title: const Text('Delivery enabled'),
                  subtitle:
                      const Text('Turn off to stop delivering to this area'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FrostButton(
              label: _isEdit ? 'Save changes' : 'Add delivery area',
              isLoading: saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
