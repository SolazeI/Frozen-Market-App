import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/cart_view.dart';
import '../../models/order.dart';
import '../../models/psgc_location.dart';
import '../../providers/cart_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/order_providers.dart';
import '../../providers/user_providers.dart';
import '../../repositories/order_repository.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Checkout for the selected cart lines, or one product ("Buy now").
/// Orders are split per seller; shipping is per seller and location.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.buyNow});
  final BuyNowItem? buyNow;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _street = TextEditingController();
  final _gcashRef = TextEditingController();
  PaymentMethod _method = PaymentMethod.cod;

  // Keeps the screen stable while the cart empties after a successful order.
  bool _placing = false;
  CartView? _snapshot;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider);
    _name.text = u?.fullName ?? '';
    _phone.text = u?.phone ?? '';
    _street.text = u?.address ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _street, _gcashRef]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _place(CartView view, PsgcLocation? loc) async {
    if (!_formKey.currentState!.validate()) return;
    if (loc == null || !loc.isComplete) {
      AppSnackbar.error(context, 'Choose a delivery location first.');
      return;
    }
    setState(() {
      _placing = true;
      _snapshot = view;
    });

    final groups = [
      for (final g in view.selectedGroups)
        PlaceOrderGroup(g.shop.shopId, [
          for (final l in g.selectedLines)
            PlaceOrderLine(l.item.productId, l.quantity),
        ]),
    ];

    final orders = await ref.read(checkoutControllerProvider.notifier).placeOrder(
          address: DeliveryAddress(
            fullName: _name.text.trim(),
            phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
            address: _street.text.trim(),
            location: loc,
          ),
          method: _method,
          paymentReference: _gcashRef.text,
          groups: groups,
          clearCart: widget.buyNow == null,
        );

    if (!mounted) return;
    if (orders != null) {
      context.pushReplacement(Routes.orderConfirmation, extra: orders);
    } else {
      setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(checkoutControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });

    final async = widget.buyNow == null
        ? ref.watch(cartViewProvider)
        : ref.watch(buyNowViewProvider(widget.buyNow!.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: (_placing && _snapshot != null)
          ? _content(_snapshot!)
          : AsyncValueView<CartView>(
              value: async,
              onRetry: () => ref.invalidate(cartItemsProvider),
              isEmpty: (v) => v.selectedGroups.isEmpty,
              empty: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Nothing to check out',
                message: 'Select items in your cart first.',
                actionLabel: 'Back to cart',
                onAction: () => context.go(Routes.customerCart),
              ),
              data: _content,
            ),
    );
  }

  Widget _content(CartView view) {
    final loc = ref.watch(selectedLocationProvider);
    final placing = ref.watch(checkoutControllerProvider).isLoading;
    final groups = view.selectedGroups;
    const gap = SizedBox(height: 14);

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _title('Delivery address'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        FrostTextField(
                            label: 'Recipient name',
                            controller: _name,
                            validator: Validators.personName),
                        gap,
                        FrostTextField(
                            label: 'Phone',
                            hint: '09XXXXXXXXX',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                Validators.phone(v, isRequired: true)),
                        gap,
                        FrostTextField(
                            label: 'Street / house no.',
                            controller: _street,
                            validator: Validators.address),
                        gap,
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(Routes.locationSelect),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.frost,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      loc?.fullLabel ??
                                          'Choose delivery location',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                const Text('Change',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _title('Order summary'),
                for (final g in groups) ...[
                  _SummaryCard(group: g),
                  const SizedBox(height: 12),
                ],
                _title('Payment method'),
                _PaymentOption(
                  icon: Icons.payments_outlined,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay the rider when your order arrives',
                  selected: _method == PaymentMethod.cod,
                  onTap: () => setState(() => _method = PaymentMethod.cod),
                ),
                const SizedBox(height: 10),
                _PaymentOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'GCash',
                  subtitle: 'Pay via GCash and enter your reference number',
                  selected: _method == PaymentMethod.gcash,
                  onTap: () => setState(() => _method = PaymentMethod.gcash),
                ),
                if (_method == PaymentMethod.gcash) ...[
                  const SizedBox(height: 12),
                  FrostTextField(
                    label: 'GCash reference number',
                    controller: _gcashRef,
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v ?? '').trim().length < 6
                        ? 'Enter your GCash reference number'
                        : null,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'The seller will verify your payment using this reference. (Demo flow: no real payment is processed.)',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
                _title('Payment details'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _line('Product subtotal', Formatters.peso(view.subtotal)),
                        const SizedBox(height: 6),
                        _line('Total shipping', Formatters.peso(view.shipping)),
                        const Divider(height: 22),
                        _line('Grand total', Formatters.peso(view.total),
                            bold: true),
                      ],
                    ),
                  ),
                ),
                if (!view.canCheckout)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "Some items can't be ordered right now (out of stock or not delivered to your location). Go back to your cart to fix them.",
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SafeArea(
            top: false,
            child: FrostButton(
              label: 'Place order • ${Formatters.peso(view.total)}',
              isLoading: placing,
              onPressed: view.canCheckout ? () => _place(view, loc) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: Text(t,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _line(String l, String v, {bool bold = false}) => Row(
        children: [
          Expanded(
              child: Text(l,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      color: bold ? null : AppColors.textSecondary))),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: bold ? 17 : 14,
                  color: bold ? AppColors.primary : null)),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.group});
  final CartGroup group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.storefront_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(group.shop.shopName,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
            ]),
            const Divider(height: 20),
            for (final l in group.selectedLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('${l.quantity}× ${l.product?.name ?? 'Item'}',
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(Formatters.peso(l.total),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(children: [
              const Expanded(
                  child: Text('Shipping',
                      style: TextStyle(color: AppColors.textSecondary))),
              Text(
                  group.delivers
                      ? Formatters.peso(group.shipping)
                      : 'Not delivered here',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: group.delivers ? null : AppColors.error)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Expanded(
                  child: Text('Seller total',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              Text(Formatters.peso(group.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.border),
            ],
          ),
        ),
      );
}
