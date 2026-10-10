import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/models/order.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/order_service.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderController extends GetxController {
  final OrderService _orderService = OrderService();

  final orderType = OrderType.dineIn.obs;
  final isSending = false.obs;

  /// Envía el pedido a la API y abre WhatsApp con el mensaje que arma el servidor.
  /// Si es por transferencia, sube también la captura del pago ([proof]).
  /// Devuelve true si el pedido quedó guardado.
  Future<bool> sendOrder(
    OrderCart order, {
    Uint8List? proof,
    String proofName = 'comprobante.jpg',
  }) async {
    if (isSending.value) return false;
    if (order.items.isEmpty) {
      Get.snackbar('Pedido vacío', 'Agrega al menos un producto');
      return false;
    }

    isSending.value = true;
    try {
      final result = await _orderService.createOrder(Session.slug, order);
      var whatsappUrl = result.whatsappUrl;

      // Comprobante de transferencia. Si falla la subida, el pedido ya quedó
      // guardado: el mensaje de WhatsApp le pide al cliente mandarlo por el chat.
      var proofFailed = false;
      if (proof != null && result.proofToken != null) {
        try {
          whatsappUrl = await _orderService.uploadProof(
                slug: Session.slug,
                orderId: result.id,
                token: result.proofToken!,
                bytes: proof,
                filename: proofName,
              ) ??
              whatsappUrl;
        } on ApiException {
          proofFailed = true;
        }
      }

      Get.find<CartController>().clearCart();
      _closeBottomSheets();

      // Diálogo con botón: abrir WhatsApp desde un toque del usuario evita
      // que el navegador bloquee la ventana emergente.
      await _showSentDialog(
        orderNumber: result.orderNumber,
        total: result.total,
        whatsappUrl: whatsappUrl,
        isTransfer: order.paymentMethod == PaymentMethod.transfer,
        proofFailed: proofFailed,
      );
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

  Future<void> _showSentDialog({
    required int orderNumber,
    required double total,
    required String? whatsappUrl,
    required bool isTransfer,
    required bool proofFailed,
  }) {
    // Nota: el aviso va dentro del diálogo y no en un snackbar, porque con un
    // snackbar abierto Get.back() cierra el snackbar en vez del diálogo.
    return Get.dialog(
      AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text('Pedido #$orderNumber enviado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${Fmt.money(total)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(isTransfer
                ? 'El restaurante revisará tu comprobante y confirmará el pedido.'
                : 'El restaurante confirmará tu pedido.'),
            if (proofFailed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No se pudo subir tu comprobante, pero el pedido sí quedó '
                  'registrado. Envía la captura del pago por WhatsApp.',
                ),
              ),
            ],
            if (whatsappUrl != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Envíale el resumen por WhatsApp para agilizar la confirmación.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
          if (whatsappUrl != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366)),
              icon: const Icon(Icons.chat),
              label: const Text('Enviar por WhatsApp'),
              onPressed: () async {
                final ok = await launchUrl(Uri.parse(whatsappUrl),
                    webOnlyWindowName: '_blank');
                Get.back();
                if (!ok) {
                  Get.snackbar('Aviso', 'No se pudo abrir WhatsApp');
                }
              },
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Cierra el selector de tipo de pedido y el formulario
  void _closeBottomSheets() {
    // Máximo 3 por seguridad (selector + formulario)
    for (var i = 0; i < 3 && Get.isBottomSheetOpen == true; i++) {
      Get.back();
    }
  }
}
