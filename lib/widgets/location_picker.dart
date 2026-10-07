import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/error_mapper.dart';
import '../models/psgc_location.dart';
import '../models/psgc_place.dart';
import '../providers/psgc_providers.dart';
import '../theme/app_colors.dart';
import 'state_views.dart';

/// Cascading Region > Province > City/Municipality > Barangay selector backed
/// by the PSGC API. Works inside a Form (validates region, city, barangay).
/// Choosing a level clears the levels below it.
class LocationPicker extends ConsumerWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.requireBarangay = true,
  });

  final PsgcLocation? value;
  final ValueChanged<PsgcLocation> onChanged;
  final bool requireBarangay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = value ?? PsgcLocation.empty;

    // Regions such as NCR have no provinces: skip the province level.
    final provinces =
        loc.hasRegion ? ref.watch(provincesProvider(loc.regionCode)) : null;
    final noProvinces = provinces?.valueOrNull?.isEmpty ?? false;

    const gap = SizedBox(height: 14);

    return FormField<PsgcLocation>(
      initialValue: loc,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (l) {
        final x = l ?? PsgcLocation.empty;
        if (!x.hasRegion) return 'Select your region';
        if (!x.hasCity) return 'Select your city or municipality';
        if (requireBarangay && !x.hasBarangay) return 'Select your barangay';
        return null;
      },
      builder: (state) {
        Future<void> pick(
          String title,
          ProviderListenable<AsyncValue<List<PsgcPlace>>> source,
          PsgcLocation Function(PsgcPlace) apply,
        ) async {
          final place = await showPlacePicker(context, title: title, source: source);
          if (place == null) return;
          final next = apply(place);
          state.didChange(next);
          onChanged(next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PickerField(
              label: 'Region',
              value: loc.region,
              enabled: true,
              onTap: () => pick('Select region', regionsProvider, loc.withRegion),
            ),
            gap,
            _PickerField(
              label: 'Province',
              value: noProvinces ? 'Not applicable' : loc.province,
              enabled: loc.hasRegion && !noProvinces,
              onTap: () => pick('Select province',
                  provincesProvider(loc.regionCode), loc.withProvince),
            ),
            gap,
            _PickerField(
              label: 'City / Municipality',
              value: loc.city,
              enabled: loc.hasRegion && (loc.hasProvince || noProvinces),
              onTap: () => pick(
                'Select city or municipality',
                citiesProvider(
                    (loc.regionCode, loc.hasProvince ? loc.provinceCode : null)),
                loc.withCity,
              ),
            ),
            gap,
            _PickerField(
              label: 'Barangay',
              value: loc.barangay,
              enabled: loc.hasCity,
              onTap: () => pick('Select barangay',
                  barangaysProvider(loc.cityCode), loc.withBarangay),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(state.errorText!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
        ),
      );
}

/// Searchable bottom sheet listing PSGC places. Returns the chosen place.
Future<PsgcPlace?> showPlacePicker(
  BuildContext context, {
  required String title,
  required ProviderListenable<AsyncValue<List<PsgcPlace>>> source,
}) =>
    showModalBottomSheet<PsgcPlace>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlacePickerSheet(title: title, source: source),
    );

class _PlacePickerSheet extends ConsumerStatefulWidget {
  const _PlacePickerSheet({required this.title, required this.source});
  final String title;
  final ProviderListenable<AsyncValue<List<PsgcPlace>>> source;

  @override
  ConsumerState<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<_PlacePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.source);
    final height = MediaQuery.sizeOf(context).height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const LoadingView(message: 'Loading locations…'),
                error: (e, _) => ErrorState(
                    title: "Couldn't load locations", message: friendlyError(e)),
                data: (places) {
                  final items = _query.isEmpty
                      ? places
                      : places
                          .where((p) => p.name.toLowerCase().contains(_query))
                          .toList();
                  if (items.isEmpty) {
                    return const Center(child: Text('No matches found'));
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i].name),
                      subtitle: items[i].subtitle == null
                          ? null
                          : Text(items[i].subtitle!),
                      onTap: () => Navigator.pop(context, items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
