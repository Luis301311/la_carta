import 'package:lacarta/core/models/cart/cart.dart';

class OrderCart {
  final List<CartItem> items;
  final String type; // OrderType.dineIn | takeaway | delivery

  final String customerName; // quien recibe, recoge o pide en la mesa
  final String? phone;
  final String? address; // si es domicilio
  final String? table; // si come en el sitio
  final String? notes;

  /// PaymentMethod.cash | PaymentMethod.transfer
  final String paymentMethod;

  OrderCart({
    required this.items,
    required this.type,
    required this.customerName,
    this.phone,
    this.address,
    this.table,
    this.notes,
    this.paymentMethod = 'cash',
  });

  /// Total estimado en el celular. El total real lo calcula la API.
  double get total => items.fold(0, (sum, item) => sum + item.total);

  /// Cuerpo para POST /public/:slug/orders.
  /// No se envían precios: la API los toma de la base de datos.
  Map<String, dynamic> toJson() {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();

    return {
      'type': type,
      'customerName': customerName.trim(),
      if (clean(phone) != null) 'phone': clean(phone),
      if (clean(address) != null) 'address': clean(address),
      if (clean(table) != null) 'tableNumber': clean(table),
      if (clean(notes) != null) 'notes': clean(notes),
      'paymentMethod': paymentMethod,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

/// Lo que devuelve la API al crear el pedido
class OrderResult {
  final String id;
  final int orderNumber;
  final double total;
  final String? whatsappUrl;

  /// Solo en pedidos por transferencia: clave para subir el comprobante
  final String? proofToken;

  OrderResult({
    required this.id,
    required this.orderNumber,
    required this.total,
    this.whatsappUrl,
    this.proofToken,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    final order = Map<String, dynamic>.from(json['order']);
    return OrderResult(
      id: order['id'],
      orderNumber: (order['orderNumber'] as num).toInt(),
      total: (order['total'] as num).toDouble(),
      whatsappUrl: json['whatsappUrl'],
      proofToken: json['proofToken'],
    );
  }
}
