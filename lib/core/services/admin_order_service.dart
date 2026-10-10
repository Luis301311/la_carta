import 'package:lacarta/core/models/admin_order.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Pedidos desde el panel (requiere sesión)
class AdminOrderService {
  final ApiClient _api = ApiClient.instance;

  Future<OrderListResult> list(
    String companyId, {
    String? status,
    DateTime? from,
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _api.get('/companies/$companyId/orders', query: {
      'status': status,
      // Se envía en UTC con hora: así "hoy" es el día local, no el de Londres
      'from': from?.toUtc().toIso8601String(),
      'page': page,
      'limit': limit,
    });
    return OrderListResult.fromJson(Map<String, dynamic>.from(data));
  }

  /// Huella de los pedidos de la empresa: cambia cada vez que hay un pedido
  /// nuevo o se modifica alguno. Es una consulta muy pequeña.
  Future<String> lastChange(String companyId) async {
    final data = await _api.get('/companies/$companyId/orders/last-change');
    return (data as Map)['version']?.toString() ?? '';
  }

  Future<AdminOrder> updateStatus(
      String companyId, String orderId, String status) async {
    final data = await _api.patch(
      '/companies/$companyId/orders/$orderId/status',
      {'status': status},
    );
    return AdminOrder.fromJson(Map<String, dynamic>.from(data));
  }
}
