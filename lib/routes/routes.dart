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
  // Customer bottom-nav branches
  static const customerSearch = '/customer/search';
  static const customerCart = '/customer/cart';
  static const customerOrders = '/customer/orders';
  static const customerProfile = '/customer/profile';
  static const checkout = '/customer/checkout';
  static const orderConfirmation = '/customer/order-confirmation';
  // Customer full-screen pages
  static const categoryPattern = '/customer/category/:name';
  static String category(String name) =>
      '/customer/category/${Uri.encodeComponent(name)}';
  static const customerProductPattern = '/customer/product/:id';
  static String customerProduct(String id) => '/customer/product/$id';
  static const customerShopPattern = '/customer/shop/:id';
  static String customerShop(String id) => '/customer/shop/$id';

  // Seller (bottom-nav branches)
  static const sellerHome = '/seller';
  static const sellerProducts = '/seller/products';
  static const sellerOrders = '/seller/orders';
  static const sellerOrderPattern = '/seller/orders/:id';
  static String sellerOrder(String id) => '/seller/orders/$id';
  static const sellerShop = '/seller/shop';
  static const editShop = '/seller/shop/edit';

  // Seller product pages (full screen, above the bottom nav)
  static const productAdd = '/seller/products/add';
  static const productDetailPattern = '/seller/products/:id';
  static const productEditPattern = '/seller/products/:id/edit';
  static String productDetail(String id) => '/seller/products/$id';
  static String productEdit(String id) => '/seller/products/$id/edit';

  // Seller delivery areas (full screen)
  static const deliveryAreas = '/seller/delivery-areas';
  static const deliveryAreaAdd = '/seller/delivery-areas/add';
  static const deliveryAreaEditPattern = '/seller/delivery-areas/:id/edit';
  static String deliveryAreaEdit(String id) => '/seller/delivery-areas/$id/edit';

  static const publicRoutes = {login, register, forgotPassword};
}
