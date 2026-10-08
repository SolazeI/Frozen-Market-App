import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/order_providers.dart';
import '../../widgets/widgets.dart';

/// Seller bottom navigation: Dashboard, Products, Orders, Shop.
/// The Orders tab shows a badge with the number of pending orders.
class SellerShell extends ConsumerWidget {
  const SellerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingOrderCountProvider);

    Widget ordersIcon(IconData icon) => Badge(
          isLabelVisible: pending > 0,
          label: Text('$pending'),
          child: Icon(icon),
        );

    return RoleGate(
      role: UserRoles.seller,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i,
              initialLocation: i == navigationShell.currentIndex),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
            const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products'),
            NavigationDestination(
                icon: ordersIcon(Icons.receipt_long_outlined),
                selectedIcon: ordersIcon(Icons.receipt_long),
                label: 'Orders'),
            const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shop'),
          ],
        ),
      ),
    );
  }
}
