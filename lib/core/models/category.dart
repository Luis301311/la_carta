class ProductCategory {
  String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;

  ProductCategory({
    this.id = '',
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  ProductCategory copyWith({
    String? name,
    String? description,
    int? sortOrder,
    bool? isActive,
  }) =>
      ProductCategory(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  /// API → Modelo
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  /// Modelo → API (crear / editar). No lleva id: lo genera Postgres.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
