
import 'package:get/get.dart';
import 'package:lacarta/core/models/cart/cart.dart';

class CartController extends GetxController {
  RxBool isLoading = false.obs; 
  var cartItems = <CartItem>[].obs;  //pedido

  void addToCart(CartItem cartItem) {
      cartItems.add(
        cartItem
      );
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

  int get totalItems =>cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalCart =>cartItems.fold(0, (sum, item) => sum + (item.total),);

  Future<void>  createCartOrder(List<CartItem> order ) async{
    isLoading.value = true;
    try {

    } catch (e) {
      Get.snackbar('Error', 'No se pudo realizar el pedido');
    } finally {
      isLoading.value = false;
    }
  }
}