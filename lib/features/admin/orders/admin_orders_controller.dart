import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/models/admin_order.dart';
import 'package:lacarta/core/services/admin_order_service.dart';
import 'package:lacarta/core/services/api_client.dart';

class AdminOrdersController extends GetxController {
  final AdminOrderService _service = AdminOrderService();

  /// Cada cuánto se pregunta a la API si algo cambió (consulta muy liviana).
  /// Así, si cocina marca un pedido en su pantalla, recepción lo ve en segundos.
  static const checkEvery = Duration(seconds: 4);

  final orders = <AdminOrder>[].obs;

  /// null = todos
  final filter = RxnString();
  final isLoading = false.obs;
  final total = 0.obs;
  final updatingId = RxnString();
  final lastUpdated = Rxn<DateTime>();

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  String? _version;
  bool _checking = false;

  /// false si la última revisión falló (sin conexión): la pantalla lo indica
  final isLive = true.obs;
  final Set<String> _knownIds = {};
  bool _firstLoad = true;

  String? get _companyId => AuthController.to.activeCompanyId.value;

  @override
  void onInit() {
    super.onInit();
    load();
    _timer = Timer.periodic(checkEvery, (_) => checkForChanges());
    // Al volver a la pestaña o a la app, revisa enseguida (el navegador
    // espacia los temporizadores de las pestañas en segundo plano)
    _lifecycle = AppLifecycleListener(onResume: checkForChanges);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.onClose();
  }

  /// Si la huella cambió desde la última vez, recarga los pedidos
  Future<void> checkForChanges() async {
    final companyId = _companyId;
    // No recargar en medio de un cambio de estado propio
    if (companyId == null || _checking || updatingId.value != null) return;
    _checking = true;
    try {
      final version = await _service.lastChange(companyId);
      isLive.value = true;
      if (version != _version) {
        _version = version;
        await load(silent: true);
      }
    } catch (_) {
      isLive.value = false;
    } finally {
      _checking = false;
    }
  }

  Future<void> load({bool silent = false}) async {
    final companyId = _companyId;
    if (companyId == null) return;
    if (!silent) isLoading.value = true;
    try {
      final res = await _service.list(companyId, status: filter.value, limit: 50);
      _notifyNewOrders(res.data);
      orders.assignAll(res.data);
      total.value = res.total;
      lastUpdated.value = DateTime.now();
    } on ApiException catch (e) {
      if (!silent) Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Avisa cuando llega un pedido nuevo entre una actualización y otra
  void _notifyNewOrders(List<AdminOrder> fresh) {
    final newOnes = fresh
        .where((o) =>
            !_knownIds.contains(o.id) && o.status == OrderStatus.pending)
        .toList();
    _knownIds.addAll(fresh.map((o) => o.id));
    if (_firstLoad) {
      _firstLoad = false;
      return;
    }
    if (newOnes.isNotEmpty) {
      Get.snackbar(
        newOnes.length == 1
            ? 'Nuevo pedido #${newOnes.first.orderNumber}'
            : '${newOnes.length} pedidos nuevos',
        newOnes.map((o) => o.customerName).join(', '),
        duration: const Duration(seconds: 5),
      );
    }
  }

  void setFilter(String? status) {
    if (filter.value == status) return;
    filter.value = status;
    load();
  }

  /// Cambia el estado. Devuelve true si la API lo aceptó.
  /// Con [offerUndo] muestra un aviso con "Deshacer" por si fue el pedido equivocado.
  Future<bool> changeStatus(AdminOrder order, String status,
      {bool offerUndo = true}) async {
    final companyId = _companyId;
    if (companyId == null || updatingId.value != null) return false;
    final previous = order.status;
    updatingId.value = order.id;
    try {
      final updated = await _service.updateStatus(companyId, order.id, status);
      _replace(updated);
      // Cancelar es definitivo: no se ofrece deshacer
      if (offerUndo && status != OrderStatus.cancelled) {
        Get.snackbar(
          'Pedido #${order.orderNumber} → ${OrderStatus.label(status)}',
          order.customerName,
          duration: const Duration(seconds: 6),
          mainButton: TextButton(
            onPressed: () {
              Get.closeCurrentSnackbar();
              changeStatus(updated, previous, offerUndo: false);
            },
            child: const Text('Deshacer'),
          ),
        );
      }
      return true;
    } on ApiException catch (e) {
      Get.snackbar('No se pudo actualizar', e.message);
      return false;
    } finally {
      updatingId.value = null;
    }
  }

  void _replace(AdminOrder updated) {
    final i = orders.indexWhere((o) => o.id == updated.id);
    if (i == -1) {
      // Volvió a un estado que coincide con el filtro (p. ej. al deshacer)
      if (filter.value == null || filter.value == updated.status) {
        orders.add(updated);
        total.value = total.value + 1;
      }
      return;
    }
    // Si hay un filtro activo y el pedido ya no cumple, sale de la lista
    if (filter.value != null && updated.status != filter.value) {
      orders.removeAt(i);
      total.value = total.value - 1;
    } else {
      orders[i] = updated;
    }
  }

  /// Orden para mostrar: viendo un estado activo, los más antiguos primero
  /// (orden de llegada); en "Todos", entregados y cancelados, los más nuevos.
  List<AdminOrder> get sortedOrders {
    final list = orders.toList();
    final f = filter.value;
    final fifo = f != null &&
        f != OrderStatus.delivered &&
        f != OrderStatus.cancelled;
    list.sort((a, b) => fifo
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
