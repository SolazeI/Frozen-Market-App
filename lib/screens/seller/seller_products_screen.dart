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

/// Products tab: the seller's product list.
class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(productControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.productAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: AsyncValueView<List<Product>>(
        value: ref.watch(myProductsProvider),
        onRetry: () => ref.invalidate(myProductsProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: "You haven't added any products yet.",
          message: 'Add your first frozen product so customers can find it.',
          actionLabel: 'Add product',
          onAction: () => context.push(Routes.productAdd),
        ),
        data: (products) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ProductTile(product: products[i]),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final Widget stock;
    if (p.stock == 0) {
      stock = const Text('Out of stock',
          style: TextStyle(
              color: AppColors.error,
              fontSize: 12.5,
              fontWeight: FontWeight.w700));
    } else if (p.stock <= 5) {
      stock = Text('Only ${p.stock} left',
          style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12.5,
              fontWeight: FontWeight.w700));
    } else {
      stock = Text('Stock: ${p.stock}',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12.5));
    }

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.productDetail(p.productId)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: NetworkImageBox(
                    url: p.imageUrl, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(Formatters.peso(p.price),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    stock,
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: p.isAvailable,
                    onChanged: (v) => ref
                        .read(productControllerProvider.notifier)
                        .setAvailability(p.productId, v),
                  ),
                  Text(p.isAvailable ? 'Listed' : 'Hidden',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
