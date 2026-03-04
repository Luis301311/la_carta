import 'package:get/get.dart';
import 'package:lacarta/controller/cart_controller.dart';
import 'package:lacarta/models/cart.dart';
import 'package:lacarta/models/cart_extras.dart';
import 'package:lacarta/models/extra_group.dart';
import 'package:lacarta/models/extra_option.dart';
import 'package:lacarta/models/producto.dart';

class ProductDetailController extends GetxController {

  final Product product;

  ProductDetailController(this.product);

  var quantity = 1.obs;

  // groupId -> { optionId : cantidad }
  RxMap<String, Map<String, int>> selectedExtras =<String, Map<String, int>>{}.obs;

  void increase() => quantity++;

  void decrease() {
    if (quantity.value > 1) {
      quantity--;
    }
  }

  // ===============================
  // EXTRAS
  // ===============================

  int getQuantity(ExtraGroup group, ExtraOption option) {
    return selectedExtras[group.id]?[option.id] ?? 0;
  }

  void incrementExtra(ExtraGroup group, ExtraOption option) {
    final groupMap = selectedExtras[group.id] ?? {};

    final totalSelected =
        groupMap.values.fold(0, (sum, qty) => sum + qty);

    if (totalSelected >= group.maxSelection) return;

    groupMap[option.id] = (groupMap[option.id] ?? 0) + 1;

    selectedExtras[group.id] = Map.from(groupMap);
  }

  void decrementExtra(ExtraGroup group, ExtraOption option) {
    final groupMap = selectedExtras[group.id];
    if (groupMap == null) return;

    final currentQty = groupMap[option.id] ?? 0;

    if (currentQty <= 1) {
      groupMap.remove(option.id);
    } else {
      groupMap[option.id] = currentQty - 1;
    }

    selectedExtras[group.id] = Map.from(groupMap);
  }

  // ===============================
  // VALIDACIÓN
  // ===============================

  bool validateRequired() {
    for (var group in product.extras) {
      if (group.isRequired) {
        final groupMap = selectedExtras[group.id] ?? {};
        final totalSelected =
            groupMap.values.fold(0, (sum, qty) => sum + qty);

        if (totalSelected < group.minSelection) {
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

  // ===============================
  // TOTALES
  // ===============================

  double get extrasTotal {
    double sum = 0;

    selectedExtras.forEach((groupId, optionsMap) {

      final group = product.extras
          .firstWhere((g) => g.id == groupId);

      optionsMap.forEach((optionId, quantity) {

        final option = group.options
            .firstWhere((o) => o.id == optionId);

        sum += option.price * quantity;
      });
    });

    return sum;
  }

  double get total =>quantity.value * (product.basePrice + extrasTotal);

  // ===============================
  // CARRITO
  // ===============================
List<CartExtra> buildCartExtras() {

  List<CartExtra> result = [];

  selectedExtras.forEach((groupId, optionsMap) {

    final group = product.extras
        .firstWhere((g) => g.id == groupId);

    optionsMap.forEach((optionId, quantity) {

      final option = group.options
          .firstWhere((o) => o.id == optionId);

      result.add(
        CartExtra(
          groupId: groupId,
          optionId: optionId,
          optionName: option.name,
          price: option.price,
          quantity: quantity,
        ),
      );
    });
  });

  return result;
}


  void addToCart() {

    if (!validateRequired()) return;

    final cartController = Get.find<CartController>();

    cartController.addToCart(
      CartItem(
        product: product,
        quantity: quantity.value,
        extras: buildCartExtras(),
      )
    );

    Get.snackbar(
      "Agregado",
      "Producto agregado al pedido",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}