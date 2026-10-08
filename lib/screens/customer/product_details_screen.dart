import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/cart_view.dart';
import '../../models/product.dart';
import '../../models/psgc_location.dart';
import '../../models/shop.dart';
import '../../providers/cart_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/marketplace_providers.dart';
import '../../providers/product_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Customer product page: details, seller, delivery availability + fee,
/// quantity selector. Out-of-area products are shown but cannot be ordered.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _qty = 1;

  Future<void> _addToCart(Product p) async {
    final ok =
        await ref.read(cartControllerProvider.notifier).addToCart(p, _qty);
    if (ok && mounted) AppSnackbar.success(context, 'Added to cart');
  }

  /// Buy now skips the cart and checks out this product only.
  void _buyNow(Product p) => context.push(Routes.checkout,
      extra: BuyNowItem(
          productId: p.productId, shopId: p.shopId, quantity: _qty));

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(cartControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.error(context, friendlyError(next.error!));
      }
    });
    final async = ref.watch(productProvider(widget.productId));
    final product = async.valueOrNull;
    final quote = product == null
        ? null
        : ref.watch(deliveryQuoteProvider(product.shopId));
    final canOrder = product != null &&
        product.isOrderable &&
        (quote?.valueOrNull != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: AsyncValueView<Product?>(
        value: async,
        onRetry: () => ref.invalidate(productProvider(widget.productId)),
        data: (p) => p == null || !p.isAvailable
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Product not available',
                message: 'This product was removed or is no longer listed.',
                actionLabel: 'Back',
                onAction: () => context.pop())
            : _body(p),
      ),
      bottomNavigationBar: product == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canOrder ? () => _addToCart(product) : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to cart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: canOrder ? () => _buyNow(product) : null,
                        child: const Text('Buy now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body(Product p) {
    final loc = ref.watch(selectedLocationProvider);
    final shop = ref.watch(shopByIdProvider(p.shopId)).valueOrNull;
    final maxQty = p.stock < 1 ? 1 : p.stock;
    if (_qty > maxQty) _qty = maxQty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NetworkImageBox(
            url: p.imageUrl,
            aspectRatio: 1.2,
            borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 16),
        Text(p.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(Formatters.peso(p.price),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
                label: Text(p.category),
                backgroundColor: AppColors.ice,
                side: BorderSide.none),
            Chip(
              label: Text(p.inStock ? '${p.stock} in stock' : 'Out of stock'),
              backgroundColor:
                  p.inStock ? AppColors.successBg : AppColors.errorBg,
              side: BorderSide.none,
            ),
            RatingSummary(rating: p.rating, reviewCount: p.reviewCount, size: 15),
          ],
        ),
        const SizedBox(height: 16),
        _DeliverySection(product: p, location: loc, shop: shop),
        const SizedBox(height: 12),
        if (shop != null) _ShopTile(shop: shop),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Quantity',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                IconButton.filledTonal(
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                IconButton.filledTonal(
                  onPressed: _qty < p.stock ? () => setState(() => _qty++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
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
                Text(p.description.isEmpty ? 'No description.' : p.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reviews', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Customer reviews will appear here.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DeliverySection extends ConsumerWidget {
  const _DeliverySection(
      {required this.product, required this.location, required this.shop});
  final Product product;
  final PsgcLocation? location;
  final Shop? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = location;
    if (loc == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Choose your delivery location'),
          subtitle: const Text('To see if this seller delivers to you.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.locationSelect),
        ),
      );
    }

    final quote = ref.watch(deliveryQuoteProvider(product.shopId));
    return quote.when(
      loading: () => const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Checking delivery to your location…'),
              ]))),
      error: (_, __) => const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("We couldn't check delivery right now."))),
      data: (area) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeliveryBadge(
                dense: false,
                delivers: area != null,
                isLocal: shop != null && shop!.location.cityCode == loc.cityCode,
                shippingFee: area?.shippingFee,
              ),
              const SizedBox(height: 10),
              if (area != null)
                Text('Shipping to ${loc.shortLabel}: ${Formatters.peso(area.shippingFee)}',
                    style: const TextStyle(color: AppColors.textSecondary))
              else ...[
                Text("This seller doesn't deliver to ${loc.shortLabel}.",
                    style: const TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () => context.push(Routes.locationSelect),
                  child: const Text('Change location'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: NetworkImageBox(
                url: shop.logoUrl,
                fallbackIcon: Icons.storefront,
                borderRadius: BorderRadius.circular(24)),
          ),
          title: Text(shop.shopName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Row(
            children: [
              Flexible(
                  child: Text(
                      [shop.city, shop.province]
                          .where((e) => e.isNotEmpty)
                          .join(', '),
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              RatingSummary(rating: shop.rating, reviewCount: shop.totalReviews),
            ],
          ),
          trailing: const Text('View shop'),
          onTap: () => context.push(Routes.customerShop(shop.shopId)),
        ),
      );
}
