class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int displayOrder; // controls UI order
  final bool isActive;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.displayOrder,
    this.isActive = true,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      displayOrder: map['displayOrder'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}


