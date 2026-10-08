import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/widgets.dart';

/// Customer bottom navigation: Home, Search, Cart, Orders, Profile.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    Widget cartIcon(IconData icon) => Badge(
          isLabelVisible: cartCount > 0,
          label: Text('$cartCount'),
          child: Icon(icon),
        );

    return RoleGate(
      role: UserRoles.customer,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i,
              initialLocation: i == navigationShell.currentIndex),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            const NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: 'Search'),
            NavigationDestination(
                icon: cartIcon(Icons.shopping_cart_outlined),
                selectedIcon: cartIcon(Icons.shopping_cart),
                label: 'Cart'),
            const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
