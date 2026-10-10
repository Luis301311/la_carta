import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/models/admin_order.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:lacarta/core/utils/whatsapp.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/orders/admin_orders_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pedidos del restaurante: filtros por estado, detalle y cambio de estado.
/// Se actualiza solo cada 20 s y avisa cuando entra un pedido nuevo.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdminOrdersController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text('Pedidos'),
            const SizedBox(width: 10),
            // Indicador "En vivo": la pantalla se mantiene al día sola
            Obx(() {
              final live = c.isLive.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (live ? Colors.green : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 8, color: live ? Colors.green : AppColors.danger),
                    const SizedBox(width: 4),
                    Text(
                      live ? 'En vivo' : 'Sin conexión',
                      style: TextStyle(
                          fontSize: 12,
                          color: live
                              ? Colors.green.shade800
                              : Colors.red.shade800),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          Obx(() {
            final t = c.lastUpdated.value;
            return t == null
                ? const SizedBox.shrink()
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'Act. ${Fmt.orderTime(t)}',
                        style: const TextStyle(
                            fontSize: 12, color: CustomColorBasic.grey1),
                      ),
                    ),
                  );
          }),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => c.load(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: Column(
          children: [
            _StatusFilter(controller: c),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: () => c.load(),
                  child: c.orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.receipt_long,
                                size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Center(child: Text('No hay pedidos aquí')),
                          ],
                        )
                      : _OrdersGrid(controller: c),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final AdminOrdersController controller;
  const _StatusFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...OrderStatus.all];
    return SizedBox(
      height: 56,
      child: Obx(() {
        final selected = controller.filter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final status = options[i];
            return ChoiceChip(
              label: Text(status == null ? 'Todos' : OrderStatus.label(status)),
              selected: selected == status,
              onSelected: (_) => controller.setFilter(status),
            );
          },
        );
      }),
    );
  }
}

/// 1, 2 o 3 columnas según el ancho
class _OrdersGrid extends StatelessWidget {
  final AdminOrdersController controller;
  const _OrdersGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      const spacing = 12.0;
      const padding = 12.0;
      // Ancho útil sin LayoutBuilder (las tarjetas tienen Obx adentro)
      final w = Responsive.contentWidth(context, 1200) - padding * 2;
      final cols = w >= 1000 ? 3 : (w >= 640 ? 2 : 1);
      final cardWidth = (w - spacing * (cols - 1)) / cols;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(padding),
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: controller.sortedOrders
              .map((o) => SizedBox(
                    width: cardWidth,
                    child: _OrderCard(
                        key: ValueKey(o.id), order: o, controller: controller),
                  ))
              .toList(),
        ),
      );
    });
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final AdminOrdersController controller;
  const _OrderCard({super.key, required this.order, required this.controller});

  String get _restaurant => AuthController.to.activeCompanyName.value;

  /// Confirmación con el número y el cliente en grande, para no cambiar
  /// el pedido equivocado. Opcionalmente avisa al cliente por WhatsApp.
  Future<void> _confirmChange(String status) async {
    final color = OrderStatus.color(status);
    final canNotify = order.phone != null &&
        CustomerWhatsApp.normalizePhone(order.phone) != null;
    var notify = canNotify;

    await Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Text('#${order.orderNumber}',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.carbon)),
                Text(order.customerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (order.tableNumber != null)
                  Text('Mesa ${order.tableNumber}',
                      style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Marcar como '),
                  TextSpan(
                    text: OrderStatus.label(status).toUpperCase(),
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ])),
                if (status == OrderStatus.cancelled)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Esta acción no se puede deshacer.',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                const SizedBox(height: 10),
                ...order.items.map((i) => Text(
                      '${i.quantity} x ${i.productName}',
                      style: const TextStyle(color: CustomColorBasic.grey1),
                    )),
                const SizedBox(height: 6),
                Text(Fmt.money(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (canNotify)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: notify,
                    activeColor: AppColors.green,
                    onChanged: (v) => setState(() => notify = v ?? false),
                    title: const Text('Avisar al cliente por WhatsApp'),
                  )
                else
                  const Text('Sin celular: no se puede avisar por WhatsApp',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: status == OrderStatus.cancelled
                    ? AppColors.danger
                    : AppColors.green,
              ),
              onPressed: () {
                // WhatsApp se abre en este mismo toque (si se abriera después
                // de esperar a la API, el navegador bloquearía la ventana)
                if (notify) {
                  final link = CustomerWhatsApp.link(order, status, _restaurant);
                  if (link != null) {
                    launchUrl(link, webOnlyWindowName: '_blank');
                  }
                }
                Get.back();
                controller.changeStatus(order, status);
              },
              child: Text('Sí, #${order.orderNumber} ${OrderStatus.label(status).toLowerCase()}'),
            ),
          ],
        );
      }),
    );
  }

  /// Escribirle al cliente en cualquier momento, con el mensaje del estado actual
  void _messageCustomer() {
    final link = CustomerWhatsApp.link(order, order.status, _restaurant);
    if (link == null) {
      Get.snackbar('Sin celular', 'Este pedido no tiene un número válido');
      return;
    }
    launchUrl(link, webOnlyWindowName: '_blank');
  }

  void _showProof() {
    final url = order.paymentProofUrl!;
    Get.dialog(
      Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comprobante · Pedido #${order.orderNumber} · ${Fmt.money(order.total)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir en otra pestaña',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => launchUrl(Uri.parse(url),
                          webOnlyWindowName: '_blank'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No se pudo cargar la imagen'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = OrderStatus.next(order.status);
    final previous = OrderStatus.previous(order.status);
    final canCancel = OrderStatus.canCancel(order.status);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD5D8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ENCABEZADO GRANDE: número + cliente (+ mesa). Es lo primero que se
          // ve para no confundir pedidos. Sin fondos de color: en momentos de
          // mucho trabajo la pantalla debe ser tranquila; el estado lo indica
          // solo el punto de color de la etiqueta.
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.carbon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(OrderType.icon(order.type),
                              size: 15, color: CustomColorBasic.grey1),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order.tableNumber != null
                                  ? 'Mesa ${order.tableNumber}'
                                  : OrderType.label(order.type),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: order.tableNumber != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (value) {
                    if (value == 'whatsapp') _messageCustomer();
                    if (value == 'back' && previous != null) {
                      _confirmChange(previous);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'whatsapp',
                      child: ListTile(
                        leading: Icon(Icons.chat),
                        title: Text('Escribir al cliente'),
                      ),
                    ),
                    if (previous != null)
                      PopupMenuItem(
                        value: 'back',
                        child: ListTile(
                          leading: const Icon(Icons.undo),
                          title: Text(
                              'Volver a "${OrderStatus.label(previous)}"'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.orderTime(order.createdAt)} · ${Fmt.ago(order.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                if (order.address != null)
                  _InfoRow(icon: Icons.place_outlined, text: order.address!),
                if (order.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: order.phone!,
                    onTap: () =>
                        launchUrl(Uri(scheme: 'tel', path: order.phone!)),
                  ),
                const SizedBox(height: 8),

                // Productos
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.quantity} x ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text(Fmt.money(item.lineTotal)),
                            ],
                          ),
                          ...item.extras.map((e) => Padding(
                                padding: const EdgeInsets.only(left: 24),
                                child: Text(
                                  '+ ${e.quantity > 1 ? '${e.quantity} x ' : ''}${e.optionName}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: CustomColorBasic.grey1),
                                ),
                              )),
                          if (item.comment != null && item.comment!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text(
                                '“${item.comment}”',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    )),

                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Nota: ${order.notes}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],

                const Divider(height: 20),

                // Pago
                Row(
                  children: [
                    Icon(PaymentMethod.icon(order.paymentMethod),
                        size: 18, color: CustomColorBasic.grey1),
                    const SizedBox(width: 6),
                    Text(PaymentMethod.label(order.paymentMethod)),
                    const Spacer(),
                    if (order.isTransfer && order.hasProof)
                      TextButton.icon(
                        onPressed: _showProof,
                        icon: const Icon(Icons.receipt, size: 18),
                        label: const Text('Ver comprobante'),
                      ),
                  ],
                ),
                if (order.isTransfer &&
                    !order.hasProof &&
                    order.status == OrderStatus.pending)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4, bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sin comprobante en la app: revisa si lo envió por WhatsApp',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),

                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(
                      Fmt.money(order.total),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Acciones
                if (next != null || canCancel) ...[
                  const SizedBox(height: 12),
                  Obx(() {
                    final busy = controller.updatingId.value == order.id;
                    return Row(
                      children: [
                        if (canCancel)
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            onPressed: busy
                                ? null
                                : () => _confirmChange(OrderStatus.cancelled),
                            child: const Text('Cancelar'),
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Escribir al cliente',
                          onPressed: _messageCustomer,
                          icon: const Icon(Icons.chat_outlined,
                              color: Color(0xFF25D366)),
                        ),
                        if (next != null)
                          FilledButton.icon(
                            // Verde = avanzar. El rojo queda solo para cancelar.
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.green),
                            onPressed:
                                busy ? null : () => _confirmChange(next),
                            icon: busy
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.arrow_forward, size: 18),
                            // En transferencias, confirmar = verificar el pago
                            label: Text(next == OrderStatus.confirmed &&
                                    order.isTransfer
                                ? 'Confirmar pago'
                                : OrderStatus.actionLabel(next)),
                          ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = OrderStatus.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            OrderStatus.label(status),
            style: const TextStyle(
                color: AppColors.carbon,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CustomColorBasic.grey1),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
