import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/shop.dart';
import '../../providers/shop_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// "Shop" tab: shop details, edit shop, and a link to the account profile.
class ShopProfileScreen extends ConsumerWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My shop')),
      body: AsyncValueView<Shop?>(
        value: ref.watch(myShopProvider),
        onRetry: () => ref.invalidate(myShopProvider),
        data: (shop) {
          if (shop == null) {
            return const ErrorState(
                title: 'Shop not found',
                message: "We couldn't find your shop.");
          }
          final location = [shop.barangay, shop.city, shop.province]
              .where((s) => s.isNotEmpty)
              .join(', ');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      NetworkImageBox(
                        url: shop.logoUrl,
                        aspectRatio: 1,
                        fallbackIcon: Icons.storefront,
                        borderRadius: BorderRadius.circular(48),
                      ).sized(96),
                      const SizedBox(height: 14),
                      Text(shop.shopName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      RatingSummary(
                          rating: shop.rating,
                          reviewCount: shop.totalReviews,
                          size: 16),
                      if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(shop.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary, height: 1.4)),
                      ],
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(location,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary))),
                          ],
                        ),
                      ],
                      if (shop.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text('Selling since ${Formatters.date(shop.createdAt!)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit shop details'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.editShop),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Account & profile'),
                      subtitle: const Text('Personal details, password, log out'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.profile),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on Widget {
  Widget sized(double s) => SizedBox(width: s, height: s, child: this);
}
