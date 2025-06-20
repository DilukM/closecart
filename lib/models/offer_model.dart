import 'package:flutter/foundation.dart';

class Offer {
  final String id;
  final String title;
  final String description;
  final double discount;
  final String shopId;
  final Map<String, dynamic>? shop;
  final List<String> tags;
  final String category;
  final double rating;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final int clicks;
  final DateTime createdAt;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.shopId,
    this.shop,
    required this.tags,
    required this.category,
    required this.rating,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.clicks,
    required this.createdAt,
  });

  // Factory method to create an Offer from JSON
  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown',
      description: json['description'] ?? 'No description available',
      discount: (json['discount'] ?? 0).toDouble(),
      shopId:
          json['shop'] is Map ? json['shop']['_id'] ?? '' : json['shop'] ?? '',
      shop: json['shop'] is Map ? json['shop'] : null,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? 'Uncategorized',
      rating: (json['rating'] ?? 0).toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now().add(Duration(days: 7)),
      imageUrl: json['imageUrl'] ??
          'https://www.foodiesfeed.com/wp-content/uploads/2023/06/burger-with-melted-cheese.jpg',
      clicks: json['clicks'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  // Check if offer is still active
  bool get isActive => DateTime.now().isBefore(endDate);

  // Get shop name safely
  String get shopName =>
      shop != null ? shop!['name'] ?? 'Unknown Shop' : 'Unknown Shop';

  @override
  String toString() =>
      'Offer(id: $id, title: $title, shopId: $shopId, shop: $shop)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Offer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
