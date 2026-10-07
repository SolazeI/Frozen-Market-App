class Routes {
  Routes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const profile = '/profile'; // both roles
  static const editProfile = '/profile/edit'; // both roles

  // Customer
  static const customerHome = '/customer';
  static const locationSelect = '/customer/location';

  // Seller (bottom-nav branches)
  static const sellerHome = '/seller';
  static const sellerProducts = '/seller/products';
  static const sellerOrders = '/seller/orders';
  static const sellerShop = '/seller/shop';
  static const editShop = '/seller/shop/edit';

  // Seller product pages (full screen, above the bottom nav)
  static const productAdd = '/seller/products/add';
  static const productDetailPattern = '/seller/products/:id';
  static const productEditPattern = '/seller/products/:id/edit';
  static String productDetail(String id) => '/seller/products/$id';
  static String productEdit(String id) => '/seller/products/$id/edit';

  static const publicRoutes = {login, register, forgotPassword};
}
