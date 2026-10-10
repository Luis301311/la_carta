import 'package:get/get.dart';
import 'package:lacarta/core/models/cart/cart.dart';

/// Solo maneja el carrito. Enviar el pedido es trabajo de OrderController.
class CartController extends GetxController {
  final cartItems = <CartItem>[].obs;

  void addToCart(CartItem cartItem) {
    cartItems.add(cartItem);
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    cartItems.refresh();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      cartItems.remove(item);
    }
    cartItems.refresh();
  }

  void clearCart() {
    cartItems.clear();
  }

  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalCart => cartItems.fold(0, (sum, item) => sum + item.total);
}
