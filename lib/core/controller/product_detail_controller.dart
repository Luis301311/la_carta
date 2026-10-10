import 'package:get/get.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/models/cart/cart.dart';
import 'package:lacarta/core/models/cart/cart_extras.dart';
import 'package:lacarta/core/models/product/extra_group.dart';
import 'package:lacarta/core/models/product/extra_option.dart';
import 'package:lacarta/core/models/product/producto.dart';

class ProductDetailController extends GetxController {
  // Antes: Get.put(CartController()) — esto REEMPLAZABA la instancia
  // que ya existe desde main.dart cada vez que se abría esta pantalla,
  // con riesgo de perder el carrito. Ahora usamos Get.find() para
  // obtener la misma instancia que ya está registrada.
  final CartController _cartController = Get.find<CartController>();

  final Product product;
  final currentPage = 0.obs;
  ProductDetailController(this.product);

  var quantity = 1.obs;
  var comment = "".obs;
  // groupId -> { optionId : cantidad }
  RxMap<String, Map<String, int>> selectedExtras = <String, Map<String, int>>{}.obs;

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

    final totalSelected = groupMap.values.fold(0, (sum, qty) => sum + qty);

    if (totalSelected >= group.maxSelection) return;

    groupMap[option.id!] = (groupMap[option.id] ?? 0) + 1;

    selectedExtras[group.id!] = Map.from(groupMap);
  }

  void decrementExtra(ExtraGroup group, ExtraOption option) {
    final groupMap = selectedExtras[group.id];
    if (groupMap == null) return;

    final currentQty = groupMap[option.id] ?? 0;

    if (currentQty <= 1) {
      groupMap.remove(option.id);
    } else {
      groupMap[option.id!] = currentQty - 1;
    }

    selectedExtras[group.id!] = Map.from(groupMap);
  }

  // ===============================
  // VALIDACIÓN
  // ===============================

  bool validateRequired() {
    for (var group in product.extras) {
      if (group.isRequired) {
        final groupMap = selectedExtras[group.id] ?? {};
        final totalSelected = groupMap.values.fold(0, (sum, qty) => sum + qty);

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
      final group = product.extras.firstWhere((g) => g.id == groupId);

      optionsMap.forEach((optionId, quantity) {
        final option = group.options.firstWhere((o) => o.id == optionId);

        sum += option.price * quantity;
      });
    });

    return sum;
  }

  double get total => quantity.value * (product.basePrice + extrasTotal);

  // ===============================
  // CARRITO
  // ===============================
  List<CartExtra> buildCartExtras() {
    List<CartExtra> result = [];

    selectedExtras.forEach((groupId, optionsMap) {
      final group = product.extras.firstWhere((g) => g.id == groupId);

      optionsMap.forEach((optionId, quantity) {
        final option = group.options.firstWhere((o) => o.id == optionId);

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

    _cartController.addToCart(
      CartItem(
        product: product,
        quantity: quantity.value,
        extras: buildCartExtras(),
        comment: comment.value,
      ),
    );

    Get.snackbar(
      "Agregado",
      "Producto agregado al pedido",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void buyNow(Product product) {
    if (!validateRequired()) return;
    _cartController.clearCart();

    _cartController.addToCart(
      CartItem(
        product: product,
        quantity: quantity.value,
        extras: buildCartExtras(),
        comment: comment.value,
      ),
    );
  }
}