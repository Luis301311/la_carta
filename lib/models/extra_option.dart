class ExtraOption {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  ExtraOption({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  factory ExtraOption.fromMap(Map<String, dynamic> map) {
    return ExtraOption(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isActive': isActive,
    };
  }
}