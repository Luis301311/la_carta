import 'package:lacarta/core/models/cart/cart_extras.dart';
import 'package:lacarta/core/models/product/producto.dart';

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

  /// Para el pedido: ids y cantidades, nada de precios
  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
      if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      'extras': extras.map((e) => e.toJson()).toList(),
    };
  }
}
