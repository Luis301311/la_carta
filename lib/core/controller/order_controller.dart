import 'package:get/get.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/models/order.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderController extends GetxController {
  final OrderService _orderService = OrderService();

  final orderType = OrderType.dineIn.obs;
  final isSending = false.obs;

  /// Envía el pedido a la API y abre WhatsApp con el mensaje que arma el servidor.
  /// Devuelve true si el pedido quedó guardado.
  Future<bool> sendOrder(OrderCart order) async {
    if (isSending.value) return false;
    if (order.items.isEmpty) {
      Get.snackbar('Pedido vacío', 'Agrega al menos un producto');
      return false;
    }

    isSending.value = true;
    try {
      final result = await _orderService.createOrder(Session.slug, order);

      Get.find<CartController>().clearCart();
      _closeBottomSheets();

      Get.snackbar(
        'Pedido #${result.orderNumber} enviado',
        'Total: \$${result.total.toStringAsFixed(0)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      final url = result.whatsappUrl;
      if (url != null) {
        final launched =
            await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
        if (!launched) {
          Get.snackbar('Aviso', 'El pedido se guardó, pero no se pudo abrir WhatsApp');
        }
      }
      return true;
    } on ApiException catch (e) {
      // Ej.: "Para domicilio se necesitan dirección y teléfono",
      // "Hamburguesa clásica: elige al menos 1 en Término de la carne"
      Get.snackbar('No se pudo enviar el pedido', e.message,
          duration: const Duration(seconds: 5));
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// Cierra el selector de tipo de pedido y el formulario
  void _closeBottomSheets() {
    // Máximo 3 por seguridad (selector + formulario)
    for (var i = 0; i < 3 && Get.isBottomSheetOpen == true; i++) {
      Get.back();
    }
  }
}
