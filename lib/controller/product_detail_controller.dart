import 'package:get/get.dart';
import 'package:lacarta/controller/cart_controller.dart';
import 'package:lacarta/models/extra_group.dart';
import 'package:lacarta/models/extra_option.dart';
import 'package:lacarta/models/producto.dart';

class ProductDetailController extends GetxController {

  final Product product;

  ProductDetailController(this.product);

  var quantity = 1.obs;

 
 var selectedExtras = <String, List<ExtraOption>>{}.obs;

  void increase() => quantity++;

  void decrease() {
    if (quantity.value > 1) {
      quantity--;
    }
  }

  void addToCart() {
    final cartController = Get.find<CartController>();
    cartController.addToCart(product, quantity.value);
    Get.snackbar(
      "Agregado",
      "Producto agregado al pedido",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void toggleExtra(ExtraGroup group, ExtraOption option) {

    final current = selectedExtras[group.title] ?? [];

    if (current.contains(option)) {
      current.remove(option);
    } else {
      if (current.length < group.maxSelection) {
        current.add(option);
      }
    }

    selectedExtras[group.title] = List.from(current);
    selectedExtras.refresh();
  }

  bool validateRequired() {
    for (var group in product.extras) {
      if (group.isRequired) {
        final selected = selectedExtras[group.title] ?? [];
        if (selected.length < group.minSelection) {
          Get.snackbar(
            "Faltan opciones",
            "Debes seleccionar ${group.title}",
          );
          return false;
        }
      }
    }

    return true;
  }



  double get extrasTotal {
    double sum = 0;

    for (var group in selectedExtras.values) {
      for (var option in group) {
        sum += option.price;
      }
    }

    return sum;
  }

  double get total =>quantity.value * (product.basePrice + extrasTotal);


  bool isSelected(ExtraGroup group, ExtraOption option) {
  final selected = selectedExtras[group.id] ?? [];
  return selected.any((o) => o.id == option.id);
}
}