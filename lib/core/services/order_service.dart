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
}
