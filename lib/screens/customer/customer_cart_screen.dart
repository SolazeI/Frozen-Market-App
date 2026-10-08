import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_view.dart';
import '../../providers/cart_providers.dart';
import '../../providers/location_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Cart grouped by seller. Each seller has its own shipping fee (Rule 5).
class CustomerCartScreen extends ConsumerWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(cartControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My cart')),
      body: AsyncValueView<CartView>(
        value: ref.watch(cartViewProvider),
        onRetry: () => ref.invalidate(cartItemsProvider),
        isEmpty: (v) => v.groups.isEmpty,
        empty: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty.',
          message: 'Browse frozen goods and add them to your cart.',
          actionLabel: 'Browse products',
          onAction: () => context.go(Routes.customerHome),
        ),
        data: (view) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: view.groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GroupCard(group: view.groups[i]),
              ),
            ),
            _CheckoutBar(view: view),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});
  final CartGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(selectedLocationProvider);
    final ctrl = ref.read(cartControllerProvider.notifier);
    final ids = group.lines.map((l) => l.item.productId).toList();
    final allSelected = group.lines.every((l) => l.selected);
    final noneSelected = group.lines.every((l) => !l.selected);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: allSelected ? true : (noneSelected ? false : null),
                  onChanged: (_) => ctrl.setGroupSelected(ids, !allSelected),
                ),
                const Icon(Icons.storefront_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        context.push(Routes.customerShop(group.shop.shopId)),
                    child: Text(group.shop.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: DeliveryBadge(
                    delivers: group.delivers,
                    isLocal: loc != null &&
                        group.shop.location.cityCode == loc.cityCode,
                    shippingFee: group.area?.shippingFee,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          for (final line in group.lines) _LineTile(line: line),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _row('Subtotal', Formatters.peso(group.subtotal)),
                const SizedBox(height: 4),
                _row(
                    'Shipping',
                    group.delivers
                        ? Formatters.peso(group.shipping)
                        : 'Seller does not deliver here',
                    valueColor: group.delivers ? null : AppColors.error),
                const SizedBox(height: 8),
                _row('Seller total', Formatters.peso(group.total), bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false, Color? valueColor}) =>
      Row(
        children: [
          Expanded(
              child: Text(l,
                  style: TextStyle(
                      color: bold ? null : AppColors.textSecondary,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? (bold ? AppColors.primary : null))),
        ],
      );
}

class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(cartControllerProvider.notifier);
    final p = line.product;
    final issue = line.issue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: line.selected,
            onChanged: (v) => ctrl.setSelected(line.item.productId, v ?? false),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: NetworkImageBox(
                url: p?.imageUrl, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.name ?? 'Unavailable product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (p != null)
                  Text(Formatters.peso(p.price),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                if (issue != null)
                  Text(issue,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                if (p != null) ...[
                  const SizedBox(height: 6),
                  _QtyStepper(
                    qty: line.quantity,
                    max: p.stock,
                    onChanged: (q) => ctrl.setQuantity(
                        line.item.productId, q,
                        stock: p.stock),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final ok = await showConfirmDialog(context,
                  title: 'Remove item?',
                  message:
                      'Remove "${p?.name ?? 'this item'}" from your cart?',
                  confirmLabel: 'Remove',
                  isDestructive: true);
              if (ok) ctrl.remove(line.item.productId);
            },
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper(
      {required this.qty, required this.max, required this.onChanged});
  final int qty;
  final int max;
  final ValueChanged<int> onChanged;

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon,
              size: 18,
              color: onTap == null ? AppColors.border : AppColors.textPrimary),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.remove, qty > 1 ? () => onChanged(qty - 1) : null),
            SizedBox(
              width: 34,
              child: Text('$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            _btn(Icons.add, qty < max ? () => onChanged(qty + 1) : null),
          ],
        ),
      );
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.view});
  final CartView view;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (view.selectedCount > 0 && !view.canCheckout)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Fix the items marked in red to continue.',
                    style: TextStyle(color: AppColors.error, fontSize: 12.5)),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      Text(Formatters.peso(view.total),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800)),
                      Text(
                          'Items ${Formatters.peso(view.subtotal)} • Shipping ${Formatters.peso(view.shipping)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: FilledButton(
                    onPressed: view.canCheckout
                        ? () => context.push(Routes.checkout)
                        : null,
                    child: Text('Checkout (${view.selectedCount})'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
