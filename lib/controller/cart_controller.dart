import 'package:get/get.dart';
import 'package:lacarta/models/cart.dart';
import 'package:lacarta/models/producto.dart';

class CartController extends GetxController {

  var cartItems = <CartItem>[].obs;

  void addToCart(Product product, int quantity) {
    final index =
        cartItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      cartItems[index].quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(
        CartItem(product: product, quantity: quantity),
      );
    }
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

  int get totalItems =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalCart =>
      cartItems.fold(
        0,
        (sum, item) => sum + (item.product.basePrice * item.quantity),
      );
}