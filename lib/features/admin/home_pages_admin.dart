import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/services/admin_order_service.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/product_services.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/create_product_page.dart';

/// Números del inicio del panel (antes eran valores inventados)
class AdminHomeController extends GetxController {
  final _orders = AdminOrderService();
  final _products = ProductServices();

  final isLoading = false.obs;
  final ordersToday = 0.obs;
  final salesToday = 0.0.obs;
  final pending = 0.obs;
  final products = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null) return;
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      // Las tres peticiones salen en paralelo
      final todayF = _orders.list(companyId, from: startOfDay, limit: 100);
      final pendingF =
          _orders.list(companyId, status: OrderStatus.pending, limit: 1);
      final productsF = _products.getProducts(companyId);

      final today = await todayF;
      final pend = await pendingF;
      final prods = await productsF;

      ordersToday.value = today.total;
      // Ventas = pedidos de hoy que no se cancelaron (primeros 100)
      salesToday.value = today.data
          .where((o) => o.status != OrderStatus.cancelled)
          .fold<double>(0, (sum, o) => sum + o.total);
      pending.value = pend.total;
      products.value = prods.length;
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (_) {
      Get.snackbar('Error', 'No se pudo cargar el resumen');
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

    return Scaffold(
      backgroundColor: CustomColorBasic.white3,
      appBar: AppBar(
        title: Obx(() => Text(
              auth.activeCompanyName.value.isEmpty
                  ? 'Panel Administrador'
                  : auth.activeCompanyName.value,
              overflow: TextOverflow.ellipsis,
            )),
        actions: [
          if (auth.isSuperAdmin)
            IconButton(
              tooltip: 'Cambiar de empresa',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => auth.leaveCompany(),
            ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => c.load(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: RefreshIndicator(
          onRefresh: () => c.load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Obx(() => Text(
                    'Hola, ${auth.user.value?.fullName ?? ''}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 4),
              const Text('Resumen de hoy',
                  style: TextStyle(color: CustomColorBasic.grey1)),
              const SizedBox(height: 16),

              // TARJETAS: 2 columnas en celular, 4 en pantallas anchas
              Builder(builder: (context) {
                // Ancho útil: hasta 1000 px menos el padding de la lista
                final maxW = Responsive.contentWidth(context, 1000) - 32;
                final cols = maxW >= 700 ? 4 : 2;
                const spacing = 12.0;
                final w =
                    (maxW - spacing * (cols - 1)) / cols;
                return Obx(() {
                  final loading = c.isLoading.value;
                  String v(String s) => loading ? '…' : s;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _StatCard(
                        width: w,
                        icon: Icons.notifications_active_outlined,
                        color: Colors.orange,
                        title: 'Pendientes',
                        value: v('${c.pending.value}'),
                        onTap: () => Get.toNamed(AppRoutes.orders),
                      ),
                      _StatCard(
                        width: w,
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        title: 'Pedidos hoy',
                        value: v('${c.ordersToday.value}'),
                        onTap: () => Get.toNamed(AppRoutes.orders),
                      ),
                      _StatCard(
                        width: w,
                        icon: Icons.attach_money,
                        color: Colors.green,
                        title: 'Ventas hoy',
                        value: v(Fmt.money(c.salesToday.value)),
                      ),
                      _StatCard(
                        width: w,
                        icon: Icons.fastfood,
                        color: Colors.purple,
                        title: 'Productos',
                        value: v('${c.products.value}'),
                      ),
                    ],
                  );
                });
              }),

              const SizedBox(height: 28),
              Text('Acciones rápidas',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              Builder(builder: (context) {
                // Ancho útil: hasta 1000 px menos el padding de la lista
                final maxW = Responsive.contentWidth(context, 1000) - 32;
                final cols = maxW >= 700 ? 4 : 2;
                const spacing = 12.0;
                final w =
                    (maxW - spacing * (cols - 1)) / cols;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _ActionButton(
                      width: w,
                      icon: Icons.receipt_long,
                      title: 'Pedidos',
                      onTap: () => Get.toNamed(AppRoutes.orders),
                    ),
                    _ActionButton(
                      width: w,
                      icon: Icons.add_box,
                      title: 'Agregar producto',
                      onTap: () => Get.to(() => const CreateProductPage()),
                    ),
                    _ActionButton(
                      width: w,
                      icon: Icons.category,
                      title: 'Categorías',
                      onTap: () => Get.snackbar(
                          'Próximamente', 'La gestión de categorías viene en el siguiente paso'),
                    ),
                    _ActionButton(
                      width: w,
                      icon: Icons.qr_code_2,
                      title: 'Métodos de pago',
                      onTap: () => Get.toNamed(AppRoutes.payments),
                    ),
                    _ActionButton(
                      width: w,
                      icon: Icons.storefront,
                      title: 'Mi restaurante',
                      onTap: () => Get.snackbar(
                          'Próximamente', 'Los datos y el horario vienen en el siguiente paso'),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(title, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.width,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 100,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
