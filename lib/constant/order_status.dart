class OrderStatus {
  static const pending = "pending";        // pedido creado
  static const confirmed = "confirmed";    // aceptado por el sistema
  static const preparing = "preparing";    // en cocina
  static const ready = "ready";            // listo para entregar
  static const delivered = "delivered";    // entregado al cliente
  static const cancelled = "cancelled";    // cancelado
}

class OrderType {
  static const dineIn = "dine_in";     // comer en el sitio
  static const takeaway = "takeaway";  // para llevar
  static const delivery = "delivery";  // domicilio
}