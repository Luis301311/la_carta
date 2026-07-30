import 'package:lacarta/core/models/cart/cart.dart';

class OrderCart {
  final List<CartItem> items;
  final String status;
  final String type;
  final DateTime createdAt;

  final String? table;        // si come en el sitio
  final String? customerName; // quien recibe o recoge
  final String? address;      // si es domicilio
  final String? phone;

  OrderCart({
    required this.items,
    required this.status,
    required this.type,
    required this.createdAt,
    this.table,
    this.customerName,
    this.address,
    this.phone,
  });

  double get total =>
      items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((e) => e.toMap()).toList(),
      'status': status,
      'type': type,
      'total': total,
      'createdAt': createdAt,
      'table': table,
      'customerName': customerName,
      'address': address,
      'phone': phone,
    };
  }
}