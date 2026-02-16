import 'package:lacarta/models/extra.dart';

class OrderItem {
  final String productId;
  final String name;
  final double basePrice;
  final int quantity;
  final List<Extra> selectedExtras;

  OrderItem({
    required this.productId,
    required this.name,
    required this.basePrice,
    required this.quantity,
    required this.selectedExtras,
  });

  double get total {
    final extrasTotal =
        selectedExtras.fold(0.0, (sum, e) => sum + e.price);
    return (basePrice + extrasTotal) * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'basePrice': basePrice,
      'quantity': quantity,
      'selectedExtras':
          selectedExtras.map((e) => e.toMap()).toList(),
      'total': total,
    };
  }
}
