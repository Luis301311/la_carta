import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int order;
  final bool isActive;
  final Timestamp? createdAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  /// 🔹 Convertir Firestore → Modelo
  factory ProductCategory.fromMap(
      Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  /// 🔹 Convertir Modelo → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
