import 'package:lacarta/models/cart_extras.dart';
import 'package:lacarta/models/producto.dart';

class CartItem {
  final Product product;
  final String comment;
  int quantity;
  final List<CartExtra> extras;

  CartItem({
    required this.product,
    required this.quantity,
    required this.extras,
    required this.comment,
  });

  double get extrasTotal => extras.fold(0, (sum, e) => sum + e.total);

  double get total => quantity * (product.basePrice + extrasTotal);

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'extras': extras.map((e) => e.toMap()).toList(),
      'extrasTotal': extrasTotal,
      'total': total,
      'comment':comment,
    };
  }
}