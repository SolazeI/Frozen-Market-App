import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/product_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Seller view of a single product: inventory controls, availability, edit, delete.
class SellerProductDetailScreen extends ConsumerWidget {
  const SellerProductDetailScreen({super.key, required this.productId});
  final String productId;

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete product?',
        message: '"${p.name}" will be removed from your shop. This can\'t be undone.',
        confirmLabel: 'Delete',
        isDestructive: true);
    if (!ok) return;
    final deleted =
        await ref.read(productControllerProvider.notifier).delete(p.productId);
    if (deleted && context.mounted) {
      AppSnackbar.success(context, 'Product deleted');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(productControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final async = ref.watch(productProvider(productId));
    final busy = ref.watch(productControllerProvider).isLoading;
    final p = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          if (p != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(Routes.productEdit(productId)),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : () => _delete(context, ref, p),
            ),
          ],
        ],
      ),
      body: AsyncValueView<Product?>(
        value: async,
        onRetry: () => ref.invalidate(productProvider(productId)),
        data: (product) {
          if (product == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Product not found',
              message: 'It may have been deleted.',
              actionLabel: 'Back to products',
              onAction: () => context.pop(),
            );
          }
          final ctrl = ref.read(productControllerProvider.notifier);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NetworkImageBox(
                  url: product.imageUrl,
                  aspectRatio: 1.3,
                  borderRadius: BorderRadius.circular(20)),
              const SizedBox(height: 16),
              Text(product.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(Formatters.peso(product.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                Chip(
                    label: Text(product.category),
                    backgroundColor: AppColors.ice,
                    side: BorderSide.none),
                Chip(
                    label: Text(product.isAvailable ? 'Listed' : 'Hidden'),
                    backgroundColor: product.isAvailable
                        ? AppColors.successBg
                        : AppColors.errorBg,
                    side: BorderSide.none),
              ]),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inventory',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            Text('${product.stock} in stock',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Remove 1',
                        onPressed: (busy || product.stock == 0)
                            ? null
                            : () => ctrl.adjustStock(product.productId, -1),
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add 1',
                        onPressed: busy
                            ? null
                            : () => ctrl.adjustStock(product.productId, 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Available to customers'),
                  subtitle: const Text('Turn off to hide this product'),
                  value: product.isAvailable,
                  onChanged: busy
                      ? null
                      : (v) => ctrl.setAvailability(product.productId, v),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                          product.description.isEmpty
                              ? 'No description.'
                              : product.description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
