import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../models/psgc_location.dart';
import '../../providers/location_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Screen 17: choose where deliveries should go. Products are then filtered by
/// sellers who deliver to this location.
class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({super.key});
  @override
  ConsumerState<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends ConsumerState<LocationSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late PsgcLocation _location =
      ref.read(selectedLocationProvider) ?? PsgcLocation.empty;

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final ok =
        await ref.read(locationControllerProvider.notifier).select(_location);
    if (ok && mounted) {
      AppSnackbar.success(context, 'Delivering to ${_location.shortLabel}');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(locationControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final loading = ref.watch(locationControllerProvider).isLoading;
    final home = ref.watch(currentUserProvider)?.location;
    final canUseHome =
        home != null && home.isComplete && home != _location;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Choose where we should deliver. You'll see products from sellers who deliver to this location, with their shipping fees.",
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (canUseHome) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Use my saved address'),
                  subtitle: Text(home.fullLabel),
                  onTap: () => setState(() => _location = home),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Key forces the pickers to rebuild with the "saved address" values.
            LocationPicker(
              key: ValueKey(_location.hashCode),
              value: _location,
              onChanged: (l) => setState(() => _location = l),
            ),
            const SizedBox(height: 28),
            FrostButton(
              label: 'Confirm location',
              icon: Icons.location_on_outlined,
              isLoading: loading,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
