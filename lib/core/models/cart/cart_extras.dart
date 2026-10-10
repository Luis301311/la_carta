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

  /// Para el pedido: solo id y cantidad (el precio lo pone la API)
  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'quantity': quantity,
    };
  }
}
