import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';

/// products/{productId}. shopId == sellerId (one shop per seller).
class Product {
  const Product({
    required this.productId,
    required this.sellerId,
    required this.shopId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.isAvailable = true,
    this.rating = 0,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String productId;
  final String sellerId;
  final String shopId;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get inStock => stock > 0;

  /// Can a customer order this right now (ignoring delivery area)?
  bool get isOrderable => isAvailable && inStock;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        productId: m['productId'] as String? ?? '',
        sellerId: m['sellerId'] as String? ?? '',
        shopId: m['shopId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? 'Other',
        price: toDouble(m['price']),
        stock: toInt(m['stock']),
        imageUrl: m['imageUrl'] as String?,
        isAvailable: m['isAvailable'] as bool? ?? true,
        rating: toDouble(m['rating']),
        reviewCount: toInt(m['reviewCount']),
        createdAt: toDate(m['createdAt']),
        updatedAt: toDate(m['updatedAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'productId': productId,
        'sellerId': sellerId,
        'shopId': shopId,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'rating': 0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
