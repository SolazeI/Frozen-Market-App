import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/market_filters.dart';
import '../../providers/location_providers.dart';
import '../../providers/marketplace_providers.dart';
import '../../routes/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Search tab, and the Category Products screen when [initialCategory] is set.
/// Searches product name, category and shop name within the customer's
/// delivery location; supports filters and sorting.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late MarketFilters _filters =
      MarketFilters(category: widget.initialCategory ?? 'All');
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<MarketFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(selectedLocationProvider);
    final feed = ref.watch(marketFeedProvider);
    final isCategoryPage = widget.initialCategory != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(isCategoryPage ? widget.initialCategory! : 'Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(query: v)),
              decoration: InputDecoration(
                hintText: 'Product, category or shop',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(
                              () => _filters = _filters.copyWith(query: ''));
                        },
                      ),
              ),
            ),
          ),
          if (!isCategoryPage)
            CategoryChips(
              selected: _filters.category,
              onSelected: (c) =>
                  setState(() => _filters = _filters.copyWith(category: c)),
            ),
          Expanded(
            child: loc == null
                ? EmptyState(
                    icon: Icons.location_on_outlined,
                    title: 'Choose your delivery location',
                    message: 'Search shows products you can have delivered.',
                    actionLabel: 'Choose location',
                    onAction: () => context.push(Routes.locationSelect))
                : AsyncValueView(
                    value: feed,
                    onRetry: () => ref.invalidate(marketFeedProvider),
                    data: (items) {
                      final results = applyFilters(items, _filters, loc);
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${results.length} products',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary)),
                                ),
                                TextButton.icon(
                                  onPressed: _openFilters,
                                  icon: const Icon(Icons.tune, size: 18),
                                  label: Text(_filters.activeCount == 0
                                      ? 'Filters'
                                      : 'Filters (${_filters.activeCount})'),
                                ),
                                PopupMenuButton<SortOption>(
                                  tooltip: 'Sort',
                                  icon: const Icon(Icons.sort),
                                  initialValue: _filters.sort,
                                  onSelected: (s) => setState(
                                      () => _filters = _filters.copyWith(sort: s)),
                                  itemBuilder: (_) => [
                                    for (final s in SortOption.values)
                                      PopupMenuItem(
                                          value: s, child: Text(s.label)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: results.isEmpty
                                ? const EmptyState(
                                    title: 'No frozen products found.',
                                    message:
                                        'Try a different search or clear your filters.')
                                : GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: ProductCard.gridDelegate,
                                    itemCount: results.length,
                                    itemBuilder: (_, i) => MarketProductCard(
                                        item: results[i], location: loc),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final MarketFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final _min = TextEditingController(
      text: widget.initial.minPrice?.toStringAsFixed(0) ?? '');
  late final _max = TextEditingController(
      text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '');
  late double _rating = widget.initial.minRating;
  late bool _inStock = widget.initial.inStockOnly;
  late bool _local = widget.initial.localOnly;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initial.withAdvanced(
        minPrice: double.tryParse(_min.text.trim()),
        maxPrice: double.tryParse(_max.text.trim()),
        minRating: _rating,
        inStockOnly: _inStock,
        localOnly: _local,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = [FilteringTextInputFormatter.digitsOnly];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('Price range',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    inputFormatters: priceFormatter,
                    decoration: const InputDecoration(
                        labelText: 'Min', prefixText: '₱ '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    inputFormatters: priceFormatter,
                    decoration: const InputDecoration(
                        labelText: 'Max', prefixText: '₱ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Minimum rating',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final r in const [0.0, 3.0, 4.0, 4.5])
                  ChoiceChip(
                    label: Text(r == 0 ? 'Any' : '$r+ ★'),
                    selected: _rating == r,
                    onSelected: (_) => setState(() => _rating = r),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('In stock only'),
              value: _inStock,
              onChanged: (v) => setState(() => _inStock = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Local sellers only'),
              subtitle: const Text('Sellers in your city'),
              value: _local,
              onChanged: (v) => setState(() => _local = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                        context, widget.initial.withAdvanced()),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _apply, child: const Text('Apply'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
