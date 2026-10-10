class ExtraOption {
  final String? id;
  final String name;
  final double price;
  final bool isActive;

  ExtraOption({
    this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  factory ExtraOption.fromJson(Map<String, dynamic> json) {
    return ExtraOption(
      id: json['id'],
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  /// Para crear/editar productos en la API (sin id: se regeneran)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'isActive': isActive,
    };
  }
}
