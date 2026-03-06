import 'package:get/get.dart';
import 'package:lacarta/constant/order_status.dart';
import 'package:lacarta/models/order.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderController  extends GetxController{
  var orderType = "dine_in".obs;
  
  //final OrderService _orderService = OrderService();

  Future<void> saveOrder(OrderCart order) async{
    await sendToWhatsApp(order);
     //await _orderService.saveOrder(order);
  }

  Future<void> sendToWhatsApp(OrderCart order) async {
    final message = buildWhatsAppMessage(order);
    final phone = "573174210412";

    final url = Uri.parse(
      "https://wa.me/$phone?text=$message",
    );

    await launchUrl(
      url,
      webOnlyWindowName: "_blank",
    );
  }




  String buildWhatsAppMessage(OrderCart order) {
    String message = "*Nuevo Pedido*\n\n";

    if (order.type == OrderType.delivery) {
      message += "*Domicilio*\n";
      message += "Cliente: ${order.customerName}\n";
      message += "Tel: ${order.phone}\n";
      message += "Dirección: ${order.address}\n\n";
    }

    if (order.type == OrderType.takeaway) {
      message += "*Para recoger*\n";
      message += "Nombre: ${order.customerName}\n";

      if (order.phone != null && order.phone!.isNotEmpty) {
        message += "Tel: ${order.phone}\n";
      }

      message += "\n";
    }

    if (order.type == OrderType.dineIn) {
      message += "*Comer en el sitio*\n";
      message += "Mesa: ${order.table}\n\n";
    }

    message += "-------------------\n";
    message += "*Pedido*\n\n";

    for (var item in order.items) {
      message += "${item.quantity} x ${item.product.name}\n";

      for (var extra in item.extras) {
        message += "   + ${extra.optionName} x${extra.quantity}\n";
      }

      if (item.comment.isNotEmpty) {
        message += "Comentario: ${item.comment}\n";
      }

      message += "   Subtotal: \$${item.total}\n\n";
    }

    message += "-------------------\n";
    message += "*TOTAL: \$${order.total}*\n";

    return Uri.encodeComponent(message);
  }
}