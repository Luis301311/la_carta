import 'package:lacarta/models/cart_extras.dart';
import 'package:lacarta/models/producto.dart';

class CartItem {
  final Product product;
  int quantity;
  final List<CartExtra> extras;

  CartItem({
    required this.product,
    required this.quantity,
    required this.extras
  });

  double get extrasTotal =>
      extras.fold(0, (sum, e) => sum + e.total);

  double get total => quantity * (product.basePrice + extrasTotal);
}