import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/market_item.dart';
import '../models/psgc_location.dart';
import '../routes/routes.dart';
import 'product_card.dart';

/// ProductCard wired to a MarketItem (delivery status + fee for the customer).
class MarketProductCard extends StatelessWidget {
  const MarketProductCard({super.key, required this.item, required this.location});

  final MarketItem item;
  final PsgcLocation? location;

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final s = item.shop;
    return ProductCard(
      name: p.name,
      price: p.price,
      sellerName: s.shopName,
      sellerLocation:
          [s.city, s.province].where((e) => e.isNotEmpty).join(', '),
      rating: p.rating,
      reviewCount: p.reviewCount,
      stock: p.stock,
      delivers: item.delivers,
      isLocal: location != null && item.isLocalTo(location!),
      shippingFee: item.shippingFee,
      imageUrl: p.imageUrl,
      onTap: () => context.push(Routes.customerProduct(p.productId)),
    );
  }
}
