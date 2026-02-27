import 'package:lacarta/models/extra.dart';

class Product {
  String? id;
  final String name;
  final String description;
  final double basePrice;
  final String categoryId;
  final String? imageUrl;
  final List<Extra> extras;
  final bool isAvailable;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    this.imageUrl,
    this.extras = const [],
    this.isAvailable = true,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] ?? true,
      extras: (map['extras'] as List<dynamic>?)
              ?.map((e) => Extra.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
    [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'extras': extras.map((e) => e.toMap()).toList(),
    };
  }
}
