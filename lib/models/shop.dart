import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';
import 'psgc_location.dart';

/// shops/{shopId}. By design shopId == sellerId (one shop per seller).
/// [location] is the shop's PSGC location, used to tell "local" products
/// (same city as the customer) from products shipped in from elsewhere.
class Shop {
  const Shop({
    required this.shopId,
    required this.sellerId,
    required this.shopName,
    this.description = '',
    this.logoUrl,
    this.address = '',
    this.location = PsgcLocation.empty,
    this.rating = 0,
    this.totalReviews = 0,
    this.totalSales = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String shopId;
  final String sellerId;
  final String shopName;
  final String description;
  final String? logoUrl;
  final String address;
  final PsgcLocation location;
  final double rating;
  final int totalReviews;
  final double totalSales;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get region => location.region;
  String get province => location.province;
  String get city => location.city;
  String get barangay => location.barangay;

  factory Shop.fromMap(Map<String, dynamic> m) => Shop(
        shopId: m['shopId'] as String? ?? '',
        sellerId: m['sellerId'] as String? ?? '',
        shopName: m['shopName'] as String? ?? '',
        description: m['description'] as String? ?? '',
        logoUrl: m['logoUrl'] as String?,
        address: m['address'] as String? ?? '',
        location: PsgcLocation.fromMap(m),
        rating: toDouble(m['rating']),
        totalReviews: toInt(m['totalReviews']),
        totalSales: toDouble(m['totalSales']),
        createdAt: toDate(m['createdAt']),
        updatedAt: toDate(m['updatedAt']),
      );

  Map<String, dynamic> toCreateMap() => {
        'shopId': shopId,
        'sellerId': sellerId,
        'shopName': shopName,
        'description': description,
        'logoUrl': logoUrl,
        'address': address,
        ...location.toMap(),
        'rating': 0,
        'totalReviews': 0,
        'totalSales': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
