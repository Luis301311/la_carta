class Extra {
  final String name;
  final double price;
  final bool isRequired;
  final bool isActive;

  Extra({
    required this.name,
    required this.price,
    this.isRequired = false,
    this.isActive = true,
  });

  factory Extra.fromMap(Map<String, dynamic> map) {
    return Extra(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      isRequired: map['isRequired'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isRequired': isRequired,
      'isActive': isActive,
    };
  }
}