import 'package:lacarta/models/order_item.dart';

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}
