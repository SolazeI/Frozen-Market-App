import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_view.dart';
import '../models/order.dart';
import '../providers/auth_providers.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/customer_cart_screen.dart';
import '../screens/customer/customer_orders_screen.dart';
import '../screens/customer/customer_shell.dart';
import '../screens/customer/location_selection_screen.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/product_details_screen.dart';
import '../screens/customer/search_screen.dart';
import '../screens/customer/shop_details_screen.dart';
import '../screens/seller/delivery_area_form_screen.dart';
import '../screens/seller/delivery_areas_screen.dart';
import '../screens/seller/seller_dashboard_screen.dart';
import '../screens/seller/edit_shop_screen.dart';
import '../screens/seller/product_form_screen.dart';
import '../screens/seller/seller_product_detail_screen.dart';
import '../screens/seller/seller_order_details_screen.dart';
import '../screens/seller/seller_orders_screen.dart';
import '../screens/seller/seller_products_screen.dart';
import '../screens/seller/seller_shell.dart';
import '../screens/seller/shop_profile_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final guard = _RouteGuard(ref);
  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: guard,
    redirect: guard.redirect,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: Routes.completeProfile,
          builder: (_, __) => const RegisterScreen(completeProfile: true)),
      // Customer area: bottom-nav shell with one branch per tab.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => CustomerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.customerHome,
                builder: (_, __) => const CustomerHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.customerSearch,
                builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.customerCart,
                builder: (_, __) => const CustomerCartScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.customerOrders,
                builder: (_, __) => const CustomerOrdersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.customerProfile,
                builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
          path: Routes.locationSelect,
          builder: (_, __) => const LocationSelectionScreen()),
      // Full-screen customer pages (open above the bottom nav).
      GoRoute(
          path: Routes.categoryPattern,
          builder: (_, s) =>
              SearchScreen(initialCategory: s.pathParameters['name']!)),
      GoRoute(
          path: Routes.customerProductPattern,
          builder: (_, s) =>
              ProductDetailsScreen(productId: s.pathParameters['id']!)),
      GoRoute(
          path: Routes.customerShopPattern,
          builder: (_, s) =>
              ShopDetailsScreen(shopId: s.pathParameters['id']!)),
      GoRoute(
          path: Routes.checkout,
          builder: (_, s) => CheckoutScreen(
              buyNow: s.extra is BuyNowItem ? s.extra as BuyNowItem : null)),
      GoRoute(
          path: Routes.orderConfirmation,
          builder: (_, s) => OrderConfirmationScreen(
              orders: s.extra is List<CustomerOrder>
                  ? s.extra as List<CustomerOrder>
                  : const <CustomerOrder>[])),
      // Seller area: bottom-nav shell with one branch per tab.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => SellerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.sellerHome,
                builder: (_, __) => const SellerDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.sellerProducts,
                builder: (_, __) => const SellerProductsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.sellerOrders,
                builder: (_, __) => const SellerOrdersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.sellerShop,
                builder: (_, __) => const ShopProfileScreen()),
          ]),
        ],
      ),
      // Full-screen seller pages (open above the bottom nav).
      GoRoute(
          path: Routes.editShop, builder: (_, __) => const EditShopScreen()),
      // Delivery areas ('add' is declared before ':id/edit').
      GoRoute(
          path: Routes.deliveryAreas,
          builder: (_, __) => const DeliveryAreasScreen()),
      GoRoute(
          path: Routes.deliveryAreaAdd,
          builder: (_, __) => const DeliveryAreaFormScreen()),
      GoRoute(
          path: Routes.deliveryAreaEditPattern,
          builder: (_, s) =>
              DeliveryAreaFormScreen(areaId: s.pathParameters['id']!)),
      GoRoute(
          path: Routes.sellerOrderPattern,
          builder: (_, s) =>
              SellerOrderDetailsScreen(orderId: s.pathParameters['id']!)),
      // 'add' is declared before ':id' so it is not read as a product id.
      GoRoute(
          path: Routes.productAdd,
          builder: (_, __) => const ProductFormScreen()),
      GoRoute(
          path: Routes.productDetailPattern,
          builder: (_, s) =>
              SellerProductDetailScreen(productId: s.pathParameters['id']!)),
      GoRoute(
          path: Routes.productEditPattern,
          builder: (_, s) =>
              ProductFormScreen(productId: s.pathParameters['id']!)),
      GoRoute(
          path: Routes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: Routes.editProfile,
          builder: (_, __) => const EditProfileScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    guard.dispose();
  });
  return router;
});

/// Central route protection: auth state + role decide where a user may be.
/// Customers can never reach /seller/* and sellers can never reach /customer/*.
class _RouteGuard extends ChangeNotifier {
  _RouteGuard(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
    _ref.listen(splashDelayProvider, (_, __) => notifyListeners());
    _ref.listen(authBusyProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final splash = _ref.read(splashDelayProvider);
    final auth = _ref.read(authStateProvider);
    final profile = _ref.read(userProfileProvider);
    final busy = _ref.read(authBusyProvider);

    // Startup: wait for splash delay + auth session restore.
    if (splash.isLoading || auth.isLoading) {
      return loc == Routes.splash ? null : Routes.splash;
    }

    // Logged out: only public routes.
    if (auth.valueOrNull == null) {
      return Routes.publicRoutes.contains(loc) ? null : Routes.login;
    }

    // Logged in, mid-registration: don't move.
    if (busy) return null;

    // Profile failed to load: splash shows retry/logout.
    if (profile.hasError) return loc == Routes.splash ? null : Routes.splash;
    if (profile.isLoading) return null;

    final user = profile.valueOrNull;
    if (user == null) {
      return loc == Routes.completeProfile ? null : Routes.completeProfile;
    }

    final home = user.isSeller ? Routes.sellerHome : Routes.customerHome;
    final inSeller = loc.startsWith(Routes.sellerHome);
    final inCustomer = loc.startsWith(Routes.customerHome);
    if (user.isSeller && inCustomer) return home;
    if (!user.isSeller && inSeller) return home;

    if (loc == Routes.splash ||
        loc == Routes.completeProfile ||
        Routes.publicRoutes.contains(loc)) {
      return home;
    }
    return null;
  }
}
