// Marketplace product — sold or affiliate-linked smart-home / security gear.
class Product {
  final String id;
  final String sku;
  final String title;
  final String vendorId;
  final String category; // e.g. 'camera', 'sensor', 'light', 'alarm'
  final double priceIls;
  final double rating; // 0..5
  final List<String> compatibility; // protocols/ecosystems it works with
  final String? affiliateUrl; // null = checkout in-app
  final String? imageUrl;
  final bool isBundle;

  const Product({
    required this.id,
    required this.sku,
    required this.title,
    required this.vendorId,
    required this.category,
    required this.priceIls,
    this.rating = 0,
    this.compatibility = const [],
    this.affiliateUrl,
    this.imageUrl,
    this.isBundle = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        sku: j['sku'] as String? ?? '',
        title: j['title'] as String? ?? '',
        vendorId: j['vendorId'] as String? ?? '',
        category: j['category'] as String? ?? '',
        priceIls: (j['priceIls'] as num?)?.toDouble() ?? 0,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        compatibility:
            (j['compatibility'] as List?)?.map((e) => '$e').toList() ?? const [],
        affiliateUrl: j['affiliateUrl'] as String?,
        imageUrl: j['imageUrl'] as String?,
        isBundle: j['isBundle'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'title': title,
        'vendorId': vendorId,
        'category': category,
        'priceIls': priceIls,
        'rating': rating,
        'compatibility': compatibility,
        'affiliateUrl': affiliateUrl,
        'imageUrl': imageUrl,
        'isBundle': isBundle,
      };
}
