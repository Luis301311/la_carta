class CartExtra {
  final String groupId;
  final String optionId;
  final String optionName;
  final double price;
  final int quantity;

  CartExtra({
    required this.groupId,
    required this.optionId,
    required this.optionName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'optionId': optionId,
      'optionName': optionName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}