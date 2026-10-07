// Phase 2 preview. Run without Firebase:
//   flutter run -t lib/main_gallery.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';

void main() => runApp(const ProviderScope(child: _GalleryApp()));

class _GalleryApp extends StatelessWidget {
  const _GalleryApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FrostMart Gallery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Gallery(),
      );
}

class _Gallery extends StatefulWidget {
  const _Gallery();
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  String _category = 'All';
  int _stars = 4;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FrostMart UI Kit')),
      body: ListView(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child:
                const Center(child: FrostLogo(onDark: true, showTagline: true)),
          ),
          const SectionHeader(title: 'Categories'),
          CategoryChips(
              selected: _category,
              onSelected: (c) => setState(() => _category = c)),
          const SectionHeader(title: 'Product cards'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: ProductCard.gridDelegate,
              children: [
                ProductCard(
                  name: 'Frozen Chicken Wings 1kg',
                  price: 285,
                  sellerName: 'Davao Frozen Hub',
                  sellerLocation: 'Davao City',
                  rating: 4.6,
                  reviewCount: 120,
                  stock: 25,
                  delivers: true,
                  isLocal: true,
                  shippingFee: 50,
                  onTap: () => AppSnackbar.info(context, 'Product tapped'),
                ),
                const ProductCard(
                  name: 'Pork Siomai (30 pcs)',
                  price: 199,
                  sellerName: 'CoolCatch Seafood',
                  sellerLocation: 'Tagum City',
                  rating: 4.2,
                  reviewCount: 34,
                  stock: 3,
                  delivers: true,
                  isLocal: false,
                  shippingFee: 80,
                ),
                const ProductCard(
                  name: 'Frozen Bangus',
                  price: 240,
                  sellerName: 'Frosty Foods Davao',
                  sellerLocation: 'Digos City',
                  rating: 0,
                  reviewCount: 0,
                  stock: 0,
                  delivers: false,
                  isLocal: false,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Buttons & fields'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const FrostTextField(
                    label: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline),
                const SizedBox(height: 12),
                FrostButton(
                  label: 'Log in',
                  isLoading: _loading,
                  onPressed: () async {
                    setState(() => _loading = true);
                    await Future.delayed(const Duration(seconds: 1));
                    if (!mounted) return;
                    setState(() => _loading = false);
                    AppSnackbar.success(context, 'Logged in');
                  },
                ),
                const SizedBox(height: 12),
                FrostButton(
                  label: 'Delete product',
                  style: FrostButtonStyle.danger,
                  icon: Icons.delete_outline,
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Delete product?',
                      message: "This can't be undone.",
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (ok && context.mounted) {
                      AppSnackbar.error(context, 'Product deleted');
                    }
                  },
                ),
                const SizedBox(height: 16),
                StarRatingInput(
                    value: _stars,
                    onChanged: (v) => setState(() => _stars = v)),
              ],
            ),
          ),
          const SectionHeader(title: 'States'),
          const SizedBox(
            height: 300,
            child: EmptyState(
              title: 'Your cart is empty',
              message: 'Browse frozen goods and add them to your cart.',
              icon: Icons.shopping_cart_outlined,
            ),
          ),
          SizedBox(
            height: 300,
            child: ErrorState(
              message: 'Check your connection and try again.',
              onRetry: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
