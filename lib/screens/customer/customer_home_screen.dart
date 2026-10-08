import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/market_item.dart';
import '../../models/psgc_location.dart';
import '../../providers/location_providers.dart';
import '../../providers/marketplace_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Customer home: branding, delivery location, search, categories and the
/// location-based product feed (nearby + shipped from other locations).
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(marketFeedProvider);
    try {
      await ref.read(marketFeedProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(selectedLocationProvider);
    final feed = ref.watch(marketFeedProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(location: loc)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: CategoryChips(
                  selected: ProductCategories.all,
                  onSelected: (c) {
                    if (c != ProductCategories.all) {
                      context.push(Routes.category(c));
                    }
                  },
                ),
              ),
            ),
            ..._content(context, ref, loc, feed),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, PsgcLocation? loc,
      AsyncValue<List<MarketItem>> feed) {
    if (loc == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.location_on_outlined,
            title: 'Choose your delivery location',
            message: 'We show products from sellers who deliver to you.',
            actionLabel: 'Choose location',
            onAction: () => context.push(Routes.locationSelect),
          ),
        ),
      ];
    }

    return feed.when(
      loading: () => [const SliverFillRemaining(child: LoadingView())],
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            message:
                "We couldn't load products. Check your connection and try again.",
            onRetry: () => ref.invalidate(marketFeedProvider),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.ac_unit_rounded,
                title: 'No frozen products found.',
                message:
                    'No sellers deliver to ${loc.shortLabel} yet. Try another location.',
                actionLabel: 'Change location',
                onAction: () => context.push(Routes.locationSelect),
              ),
            ),
          ];
        }

        final local = items.where((i) => i.isLocalTo(loc)).toList();
        final remote = items.where((i) => !i.isLocalTo(loc)).toList();
        final top = items.where((i) => i.product.reviewCount > 0).toList()
          ..sort((a, b) => b.product.rating.compareTo(a.product.rating));

        return [
          if (top.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Recommended')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 330,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: top.length > 8 ? 8 : top.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                      width: 170,
                      child: MarketProductCard(item: top[i], location: loc)),
                ),
              ),
            ),
          ],
          if (local.isNotEmpty) ..._grid('Nearby products', local, loc),
          if (remote.isNotEmpty)
            ..._grid('From other locations', remote, loc),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
      },
    );
  }

  List<Widget> _grid(String title, List<MarketItem> items, PsgcLocation loc) => [
        SliverToBoxAdapter(child: SectionHeader(title: title)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: ProductCard.gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, i) => MarketProductCard(item: items[i], location: loc),
              childCount: items.length,
            ),
          ),
        ),
      ];
}

class _Header extends StatelessWidget {
  const _Header({required this.location});
  final PsgcLocation? location;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.ac_unit_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(AppConstants.appName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 2),
          const Text(AppConstants.tagline,
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(Routes.locationSelect),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location == null
                          ? 'Choose delivery location'
                          : 'Deliver to: ${location!.shortLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Text('Change',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go(Routes.customerSearch),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Search frozen goods…',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
