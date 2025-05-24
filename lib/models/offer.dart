class Offer {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final double price;
  final double discount;
  final double latitude;
  final double longitude;
  final String storeName;
  final String? category;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.discount,
    required this.latitude,
    required this.longitude,
    required this.storeName,
    this.category,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      storeName: json['storeName'] ?? '',
      category: json['category'],
    );
  }
}
