import 'package:lacarta/core/models/product/extra_group.dart';

class Product {
  String? id;
  final String name;
  final String description;
  final double basePrice;
  final String categoryId;

  /// En la API se llama `imageUrls`
  final List<String> imageUrl;

  /// En la API se llama `extraGroups`
  final List<ExtraGroup> extras;
  final bool isAvailable;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    this.imageUrl = const [],
    this.extras = const [],
    this.isAvailable = true,
  });

  /// Primera imagen o null si el producto no tiene fotos
  String? get mainImage => imageUrl.isNotEmpty ? imageUrl.first : null;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      categoryId: json['categoryId'] ?? '',
      imageUrl: List<String>.from(json['imageUrls'] ?? const []),
      isAvailable: json['isAvailable'] ?? true,
      extras: ((json['extraGroups'] as List?) ?? [])
          .map((e) => ExtraGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Cuerpo para POST/PATCH /companies/:companyId/products
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'imageUrls': imageUrl,
      'isAvailable': isAvailable,
      'extraGroups': extras.map((e) => e.toJson()).toList(),
    };
  }
}
