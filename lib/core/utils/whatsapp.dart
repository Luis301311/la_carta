import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/models/admin_order.dart';
import 'package:lacarta/core/utils/format.dart';

/// Mensajes de WhatsApp del restaurante al cliente, según el estado.
class CustomerWhatsApp {
  /// "300 123 4567" -> "573001234567" (agrega el 57 a celulares colombianos)
  static String? normalizePhone(String? phone) {
    var digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 10 && digits.startsWith('3')) digits = '57$digits';
    return digits.length >= 8 ? digits : null;
  }

  static String _firstName(String name) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? '' : ' $first';
  }

  /// Texto según el estado (y el tipo de pedido)
  static String message(AdminOrder o, String status, String restaurant) {
    final hola = '¡Hola${_firstName(o.customerName)}!';
    final pedido = 'tu pedido *#${o.orderNumber}*';
    final tuPedido = 'Tu pedido *#${o.orderNumber}*';
    final en = restaurant.isEmpty ? '' : ' en *$restaurant*';

    switch (status) {
      case OrderStatus.pending:
        return o.isTransfer
            ? '$hola Recibimos $pedido$en. Estamos verificando tu pago, ya te confirmamos 🙌'
            : '$hola Recibimos $pedido$en. En un momento te lo confirmamos 🙌';
      case OrderStatus.confirmed:
        return o.isTransfer
            ? '$hola Recibimos tu pago ✅ $tuPedido$en está confirmado y pasa a preparación.\nTotal: ${Fmt.money(o.total)}'
            : '$hola $tuPedido$en está confirmado ✅ Total a pagar: ${Fmt.money(o.total)}';
      case OrderStatus.preparing:
        return '$hola Ya estamos preparando $pedido 👨‍🍳';
      case OrderStatus.ready:
        switch (o.type) {
          case OrderType.delivery:
            return '$hola $tuPedido va en camino 🛵${o.address != null ? '\nDirección: ${o.address}' : ''}';
          case OrderType.dineIn:
            return '$hola $tuPedido está listo, ya te lo llevamos${o.tableNumber != null ? ' a la mesa ${o.tableNumber}' : ''} 🍽️';
          default:
            return '$hola $tuPedido está listo para recoger 🛍️ Muestra el número *#${o.orderNumber}* al reclamarlo.';
        }
      case OrderStatus.delivered:
        return '$hola ¡Gracias por tu compra! Esperamos que disfrutes $pedido 😋';
      case OrderStatus.cancelled:
        return '$hola Lo sentimos, $pedido fue cancelado. Escríbenos si tienes alguna duda.';
      default:
        return '$hola Te escribimos por $pedido$en.';
    }
  }

  /// Link wa.me al número del cliente con el mensaje listo, o null si no hay teléfono
  static Uri? link(AdminOrder o, String status, String restaurant) {
    final phone = normalizePhone(o.phone);
    if (phone == null) return null;
    return Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message(o, status, restaurant))}');
  }
}
