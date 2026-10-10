/// Respuesta de GET /companies/:id/dashboard
class DashboardData {
  final DateTime? todayDate;
  final int ordersToday;
  final double salesToday;
  final int pending;
  final int? salesTrendPct; // hoy vs. ayer
  final List<DaySales> week;
  final double weekTotal;
  final int? weekTrendPct; // esta semana vs. la anterior
  final int productsTotal;
  final int productsAvailable;
  final List<RecentOrder> recentOrders;

  DashboardData({
    this.todayDate,
    required this.ordersToday,
    required this.salesToday,
    required this.pending,
    this.salesTrendPct,
    required this.week,
    required this.weekTotal,
    this.weekTrendPct,
    required this.productsTotal,
    required this.productsAvailable,
    required this.recentOrders,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final today = Map<String, dynamic>.from(j['today'] ?? {});
    final products = Map<String, dynamic>.from(j['products'] ?? {});
    return DashboardData(
      todayDate: DateTime.tryParse(today['date'] ?? ''),
      ordersToday: (today['orders'] as num?)?.toInt() ?? 0,
      salesToday: (today['sales'] as num?)?.toDouble() ?? 0,
      pending: (today['pending'] as num?)?.toInt() ?? 0,
      salesTrendPct: (today['salesTrendPct'] as num?)?.toInt(),
      week: ((j['week'] as List?) ?? [])
          .map((e) => DaySales.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      weekTotal: (j['weekTotal'] as num?)?.toDouble() ?? 0,
      weekTrendPct: (j['weekTrendPct'] as num?)?.toInt(),
      productsTotal: (products['total'] as num?)?.toInt() ?? 0,
      productsAvailable: (products['available'] as num?)?.toInt() ?? 0,
      recentOrders: ((j['recentOrders'] as List?) ?? [])
          .map((e) => RecentOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DaySales {
  final DateTime date;
  final double sales;
  final int orders;
  DaySales({required this.date, required this.sales, required this.orders});

  factory DaySales.fromJson(Map<String, dynamic> j) => DaySales(
        date: DateTime.parse(j['date']),
        sales: (j['sales'] as num?)?.toDouble() ?? 0,
        orders: (j['orders'] as num?)?.toInt() ?? 0,
      );
}

class RecentOrder {
  final String id;
  final int orderNumber;
  final String status;
  final String customerName;
  final double total;
  final DateTime createdAt;
  final int units;

  RecentOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.total,
    required this.createdAt,
    required this.units,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> j) => RecentOrder(
        id: j['id'],
        orderNumber: (j['orderNumber'] as num).toInt(),
        status: j['status'] ?? '',
        customerName: j['customerName'] ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        units: (j['units'] as num?)?.toInt() ?? 0,
      );
}
