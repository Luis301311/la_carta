import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/models/dashboard.dart';
import 'package:lacarta/core/services/admin_order_service.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:lacarta/features/admin/dashboard/weekly_sales_chart.dart';
import 'package:lacarta/features/admin/shell/admin_shell.dart';
import 'package:lacarta/features/admin/shell/admin_shell_controller.dart';

/// Datos del inicio del panel (una sola petición a /dashboard)
class AdminHomeController extends GetxController {
  final _service = AdminOrderService();
  final data = Rxn<DashboardData>();
  final isLoading = false.obs;
  final error = RxnString();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    load();
    // Se refresca solo cada 30 s mientras está abierto
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => load(silent: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null) return;
    if (!silent) isLoading.value = true;
    try {
      data.value = await _service.dashboard(companyId);
      error.value = null;
      if (Get.isRegistered<AdminShellController>()) {
        AdminShellController.to.pending.value = data.value!.pending;
      }
    } on ApiException catch (e) {
      if (!silent) error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}

class HomePagesAdmin extends StatelessWidget {
  const HomePagesAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final c = Get.put(AdminHomeController());
    final screen = MediaQuery.sizeOf(context).width;
    final wide = screen >= kSidebarBreakpoint;
    // Ancho útil del contenido (sin la barra lateral), máx. 1200
    final content =
        ((wide ? screen - kSidebarWidth : screen) - 32).clamp(0.0, 1200.0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: wide
            ? null
            : Obx(() => Text(
                  auth.activeCompanyName.value.isEmpty
                      ? 'Panel'
                      : auth.activeCompanyName.value,
                  overflow: TextOverflow.ellipsis,
                )),
        actions: [
          // Campana = pedidos por confirmar
          Obx(() {
            final n = Get.isRegistered<AdminShellController>()
                ? AdminShellController.to.pending.value
                : (c.data.value?.pending ?? 0);
            return IconButton(
              tooltip: n == 0 ? 'Sin pedidos por confirmar' : '$n por confirmar',
              onPressed: () => goToSection(AppRoutes.orders),
              icon: Badge(
                isLabelVisible: n > 0,
                label: Text('$n'),
                backgroundColor: AppColors.amber,
                child: const Icon(Icons.notifications_outlined),
              ),
            );
          }),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => c.load(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => c.load(),
        child: Obx(() {
          final d = c.data.value;
          if (d == null) {
            if (c.error.value != null) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text(c.error.value!)),
                Center(
                  child: TextButton(
                      onPressed: () => c.load(), child: const Text('Reintentar')),
                ),
              ]);
            }
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Center(
                child: SizedBox(
                  width: content,
                  child: _Content(data: d, width: content, wide: wide),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DashboardData data;
  final double width;
  final bool wide;
  const _Content({required this.data, required this.width, required this.wide});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final firstName = (auth.user.value?.fullName ?? '').split(' ').first;
    final twoColumns = width >= 860; // gráfica y pedidos lado a lado

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SALUDO
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Hola${firstName.isEmpty ? '' : ', $firstName'}!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Text('Aquí tienes un resumen de tu restaurante',
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('Hoy, ${Fmt.dateLong(data.todayDate ?? DateTime.now())}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // INDICADORES
        _KpiGrid(data: data, width: width),
        const SizedBox(height: 16),

        // BOTÓN GRANDE (celular): al alcance del pulgar
        if (!wide) ...[
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => goToSection(AppRoutes.orders),
              icon: const Icon(Icons.receipt_long),
              label: Text(data.pending > 0
                  ? 'Ver pedidos (${data.pending} por confirmar)'
                  : 'Ver pedidos'),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // GRÁFICA + PEDIDOS RECIENTES
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _SalesCard(data: data)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _RecentOrdersCard(orders: data.recentOrders)),
            ],
          )
        else ...[
          _SalesCard(data: data),
          const SizedBox(height: 16),
          _RecentOrdersCard(orders: data.recentOrders),
        ],
        const SizedBox(height: 16),

        // ACCESOS RÁPIDOS
        _QuickAccess(width: width),
      ],
    );
  }
}

// ------------------------------------------------------------ Indicadores

class _KpiGrid extends StatelessWidget {
  final DashboardData data;
  final double width;
  const _KpiGrid({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    final cols = width >= 820 ? 4 : 2;
    const gap = 12.0;
    final w = (width - gap * (cols - 1)) / cols;
    final pendingAlert = data.pending > 0;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        // Por confirmar: el más urgente; se resalta si hay pedidos esperando
        _KpiCard(
          width: w,
          icon: Icons.schedule,
          value: '${data.pending}',
          label: 'Por confirmar',
          highlight: pendingAlert,
          onTap: () => goToSection(AppRoutes.orders),
        ),
        _KpiCard(
          width: w,
          icon: Icons.shopping_bag_outlined,
          value: '${data.ordersToday}',
          label: 'Pedidos hoy',
          onTap: () => goToSection(AppRoutes.orders),
        ),
        _KpiCard(
          width: w,
          icon: Icons.attach_money,
          value: Fmt.money(data.salesToday),
          label: 'Ventas de hoy',
          trendPct: data.salesTrendPct,
          trendLabel: 'vs. ayer',
        ),
        _KpiCard(
          width: w,
          icon: Icons.inventory_2_outlined,
          value: '${data.productsAvailable} de ${data.productsTotal}',
          label: 'Productos disponibles',
          onTap: () => goToSection(AppRoutes.products),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String value;
  final String label;
  /// Resaltar (p. ej. hay pedidos por confirmar): borde y número en coral
  final bool highlight;
  final int? trendPct;
  final String? trendLabel;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
    this.trendPct,
    this.trendLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlight ? AppColors.amber : AppColors.carbon;
    final t = trendPct;
    return SizedBox(
      width: width,
      child: Material(
        color: highlight ? AppColors.amberSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highlight ? AppColors.amber : AppColors.border,
            width: highlight ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.coral, size: 28),
                    const Spacer(),
                    if (t != null)
                      Text(
                        '${t >= 0 ? '↗' : '↘'} ${t >= 0 ? '+' : ''}$t%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t >= 0 ? AppColors.green : AppColors.danger,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: textColor),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trendLabel != null && t != null ? '$label · $trendLabel' : label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54),
                      ),
                    ),
                    if (onTap != null)
                      Icon(Icons.chevron_right, size: 18, color: textColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Gráfica

class _SalesCard extends StatelessWidget {
  final DashboardData data;
  const _SalesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = data.weekTrendPct;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Ventas de la semana',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                if (t != null)
                  Text(
                    '${t >= 0 ? '↗ +' : '↘ '}$t% vs. semana anterior',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t >= 0 ? AppColors.green : AppColors.danger),
                  ),
              ],
            ),
            Text('Total: ${Fmt.money(data.weekTotal)}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 12),
            WeeklySalesChart(days: data.week),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Pedidos recientes

class _RecentOrdersCard extends StatelessWidget {
  final List<RecentOrder> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Pedidos recientes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => goToSection(AppRoutes.orders),
                  child: const Text('Ver todos',
                      style: TextStyle(color: AppColors.coralDark)),
                ),
              ],
            ),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Aún no hay pedidos')),
              ),
            ...orders.map((o) {
              final color = OrderStatus.color(o.status);
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => goToSection(AppRoutes.orders),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 104,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          OrderStatus.label(o.status),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('#${o.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${Fmt.orderTime(o.createdAt)} · ${o.units} prod.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      Text(Fmt.money(o.total),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Accesos rápidos

class _QuickAccess extends StatelessWidget {
  final double width;
  const _QuickAccess({required this.width});

  @override
  Widget build(BuildContext context) {
    final cols = width >= 900 ? 5 : (width >= 560 ? 3 : 2);
    const gap = 12.0;
    final w = (width - 32 - gap * (cols - 1)) / cols;

    final items = [
      (Icons.receipt_long, 'Pedidos', 'Ver y gestionar', AppRoutes.orders),
      (Icons.inventory_2_outlined, 'Productos', 'Precios y agotados', AppRoutes.products),
      (Icons.sell_outlined, 'Categorías', 'Organizar el menú', AppRoutes.categories),
      (Icons.credit_card, 'Métodos de pago', 'Efectivo y Bre-B', AppRoutes.payments),
      (Icons.storefront_outlined, 'Mi restaurante', 'Datos y horario', AppRoutes.restaurant),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accesos rápidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items
                  .map((it) => SizedBox(
                        width: w,
                        child: Material(
                          color: AppColors.gray,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => goToSection(it.$4),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(it.$1, color: AppColors.coral),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(it.$2,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      const Icon(Icons.chevron_right, size: 18),
                                    ],
                                  ),
                                  Text(it.$3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
