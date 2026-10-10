/// Pedido tal como lo devuelve la API al panel
class AdminOrder {
  final String id;
  final int orderNumber;
  final String status;
  final String type;
  final String customerName;
  final String? phone;
  final String? address;
  final String? tableNumber;
  final String? notes;
  final double total;
  final DateTime createdAt;
  final List<AdminOrderItem> items;

  /// 'cash' | 'transfer'
  final String paymentMethod;
  final String? paymentProofUrl;

  bool get isTransfer => paymentMethod == 'transfer';
  bool get hasProof => paymentProofUrl != null && paymentProofUrl!.isNotEmpty;

  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.type,
    required this.customerName,
    this.phone,
    this.address,
    this.tableNumber,
    this.notes,
    required this.total,
    required this.createdAt,
    required this.items,
    this.paymentMethod = 'cash',
    this.paymentProofUrl,
  });

  int get totalUnits => items.fold(0, (s, i) => s + i.quantity);

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'],
      orderNumber: (json['orderNumber'] as num).toInt(),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      customerName: json['customerName'] ?? '',
      phone: json['phone'],
      address: json['address'],
      tableNumber: json['tableNumber'],
      notes: json['notes'],
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      items: ((json['items'] as List?) ?? [])
          .map((e) => AdminOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentProofUrl: json['paymentProofUrl'],
    );
  }
}

class AdminOrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double extrasTotal;
  final double lineTotal;
  final String? comment;
  final List<AdminOrderExtra> extras;

  AdminOrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.extrasTotal,
    required this.lineTotal,
    this.comment,
    required this.extras,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      extrasTotal: (json['extrasTotal'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      comment: json['comment'],
      extras: ((json['extras'] as List?) ?? [])
          .map((e) => AdminOrderExtra.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class AdminOrderExtra {
  final String groupTitle;
  final String optionName;
  final int quantity;
  final double unitPrice;

  AdminOrderExtra({
    required this.groupTitle,
    required this.optionName,
    required this.quantity,
    required this.unitPrice,
  });

  factory AdminOrderExtra.fromJson(Map<String, dynamic> json) {
    return AdminOrderExtra(
      groupTitle: json['groupTitle'] ?? '',
      optionName: json['optionName'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Página de resultados de GET /companies/:id/orders
class OrderListResult {
  final List<AdminOrder> data;
  final int total;
  final int page;
  final int pages;

  OrderListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory OrderListResult.fromJson(Map<String, dynamic> json) {
    return OrderListResult(
      data: ((json['data'] as List?) ?? [])
          .map((e) => AdminOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }
}
