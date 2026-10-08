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
                padding: const EdgeInsets.only(top: 20),
                child: CategoryTiles(
                  onSelected: (c) => context.push(Routes.category(c)),
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
      loading: () => [
        const SliverToBoxAdapter(
            child: SectionHeader(title: 'Nearby products')),
        const SliverToBoxAdapter(
            child: SkeletonProductGrid(count: 6, shrinkWrap: true)),
      ],
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
            const SliverToBoxAdapter(
                child: SectionHeader(
                    title: 'Recommended', subtitle: 'Top rated for you')),
            SliverToBoxAdapter(
              child: FadeIn(
                child: SizedBox(
                  height: 335,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: top.length > 8 ? 8 : top.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => SizedBox(
                        width: 172,
                        child: MarketProductCard(item: top[i], location: loc)),
                  ),
                ),
              ),
            ),
          ],
          if (local.isNotEmpty)
            ..._grid('Nearby products', 'Sellers in ${loc.city}', local, loc),
          if (remote.isNotEmpty)
            ..._grid('From other locations', 'They deliver to you too',
                remote, loc),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
      },
    );
  }

  List<Widget> _grid(String title, String subtitle, List<MarketItem> items,
          PsgcLocation loc) =>
      [
        SliverToBoxAdapter(
            child: SectionHeader(title: title, subtitle: subtitle)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: ProductCard.gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, i) => FadeIn(
                duration: Duration(milliseconds: 240 + (i < 6 ? i * 60 : 360)),
                child: MarketProductCard(item: items[i], location: loc),
              ),
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
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.ac_unit_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConstants.appName,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    Text(AppConstants.tagline,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(Routes.locationSelect),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14)),
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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.go(Routes.customerSearch),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Search frozen goods, shops…',
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
