/// Brand strings, roles and Firestore collection names in one place.
class AppConstants {
  AppConstants._();
  static const appName = 'FrostMart';
  static const tagline = 'Freshly Frozen. Delivered to You.';
  static const currencySymbol = '₱';
}

class UserRoles {
  UserRoles._();
  static const customer = 'customer';
  static const seller = 'seller';
}

class Collections {
  Collections._();
  static const users = 'users';
  static const shops = 'shops';
  static const products = 'products';
  static const orders = 'orders';
  static const reviews = 'reviews'; // product reviews: {orderId}_{productId}
  static const sellerReviews = 'sellerReviews'; // seller ratings: {orderId}
  static const deliveryAreas = 'deliveryAreas'; // shops/{shopId}/deliveryAreas
}

class ProductCategories {
  ProductCategories._();
  static const all = 'All';
  static const list = <String>[
    'Frozen Meat',
    'Seafood',
    'Chicken',
    'Pork',
    'Beef',
    'Ready-to-Cook',
    'Processed Food',
    'Frozen Vegetables',
    'Other',
  ];
}
