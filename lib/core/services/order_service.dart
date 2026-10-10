import 'dart:typed_data';

import 'package:lacarta/core/models/order.dart';
import 'package:lacarta/core/services/api_client.dart';

class OrderService {
  final ApiClient _api = ApiClient.instance;

  /// POST /public/:slug/orders
  /// La API valida productos y extras, calcula el total y devuelve
  /// el número de pedido y el link de WhatsApp ya armado.
  Future<OrderResult> createOrder(String slug, OrderCart order) async {
    final data = await _api.post(
      '/public/${Uri.encodeComponent(slug)}/orders',
      order.toJson(),
    );
    return OrderResult.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /public/:slug/orders/:orderId/proof (captura del pago).
  /// Devuelve el nuevo link de WhatsApp (que ya dice "comprobante adjunto").
  Future<String?> uploadProof({
    required String slug,
    required String orderId,
    required String token,
    required Uint8List bytes,
    required String filename,
  }) async {
    final data = await _api.uploadImage(
      '/public/${Uri.encodeComponent(slug)}/orders/$orderId/proof',
      bytes,
      filename: filename,
      fields: {'token': token},
    );
    return (data as Map)['whatsappUrl'] as String?;
  }
}
