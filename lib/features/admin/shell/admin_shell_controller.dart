import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/services/admin_order_service.dart';
import 'package:lacarta/core/services/company_service.dart';

/// Datos que muestra el layout del panel en todas las pantallas:
/// logo y portada del restaurante, y el contador de pedidos por confirmar.
class AdminShellController extends GetxController {
  static AdminShellController get to => Get.find<AdminShellController>();

  final _orders = AdminOrderService();
  final _companies = CompanyService();

  final logoUrl = RxnString();
  final coverUrl = RxnString();

  /// Pedidos "por confirmar" (globito rojo en Pedidos)
  final pending = 0.obs;

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  Worker? _companyWorker;
  String? _loadedFor;

  @override
  void onInit() {
    super.onInit();
    _companyWorker = ever<String?>(
      AuthController.to.activeCompanyId,
      (_) => refreshAll(),
    );
    refreshAll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => refreshPending());
    _lifecycle = AppLifecycleListener(onResume: refreshPending);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    _companyWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshAll() async {
    final id = AuthController.to.activeCompanyId.value;
    if (id == null) {
      logoUrl.value = null;
      coverUrl.value = null;
      pending.value = 0;
      _loadedFor = null;
      return;
    }
    if (_loadedFor != id) {
      _loadedFor = id;
      try {
        final c = await _companies.getCompany(id);
        logoUrl.value = c.logoUrl.isEmpty ? null : c.logoUrl;
        coverUrl.value = c.coverUrl;
      } catch (_) {/* el panel funciona igual sin logo */}
    }
    await refreshPending();
  }

  /// Llamarlo también después de guardar logo/portada en "Mi restaurante"
  Future<void> reloadBranding() async {
    _loadedFor = null;
    await refreshAll();
  }

  Future<void> refreshPending() async {
    final id = AuthController.to.activeCompanyId.value;
    if (id == null) return;
    try {
      final res = await _orders.list(id, status: OrderStatus.pending, limit: 1);
      pending.value = res.total;
    } catch (_) {/* sin conexión: se mantiene el último valor */}
  }
}
