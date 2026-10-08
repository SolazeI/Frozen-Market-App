import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/delivery_area.dart';
import '../../providers/delivery_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Seller: list, enable/disable, edit and delete delivery areas.
class DeliveryAreasScreen extends ConsumerWidget {
  const DeliveryAreasScreen({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, DeliveryArea a) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete delivery area?',
        message:
            'Customers in ${a.label} will no longer see your products.',
        confirmLabel: 'Delete',
        isDestructive: true);
    if (!ok) return;
    final done = await ref
        .read(deliveryAreaControllerProvider.notifier)
        .deleteArea(a.areaId);
    if (done && context.mounted) {
      AppSnackbar.success(context, 'Delivery area deleted');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(deliveryAreaControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery areas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.deliveryAreaAdd),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add area'),
      ),
      body: AsyncValueView<List<DeliveryArea>>(
        value: ref.watch(myDeliveryAreasProvider),
        onRetry: () => ref.invalidate(myDeliveryAreasProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'Add a delivery area so customers can find your products.',
          message:
              'Customers only see your products if you deliver to their location.',
          actionLabel: 'Add delivery area',
          onAction: () => context.push(Routes.deliveryAreaAdd),
        ),
        data: (areas) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.frost,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A barangay area overrides the city fee for that barangay.',
                      style: TextStyle(fontSize: 12.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final a in areas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                    leading: CircleAvatar(
                      backgroundColor:
                          a.isActive ? AppColors.ice : AppColors.border,
                      child: Icon(
                          a.isBarangayLevel
                              ? Icons.location_on_outlined
                              : Icons.location_city_outlined,
                          color: a.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary),
                    ),
                    title: Text(a.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${Formatters.peso(a.shippingFee)} • ${a.coverageLabel}'
                        '${a.isActive ? '' : ' • Disabled'}'),
                    onTap: () =>
                        context.push(Routes.deliveryAreaEdit(a.areaId)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: a.isActive,
                          onChanged: (v) => ref
                              .read(deliveryAreaControllerProvider.notifier)
                              .setActive(a.areaId, v),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              context.push(Routes.deliveryAreaEdit(a.areaId));
                            } else {
                              _delete(context, ref, a);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit fee')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
