import 'dart:async';

import 'package:get/get.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/models/menu.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/company_service.dart';
import 'package:lacarta/core/services/menu_service.dart';

/// Restaurante que se está viendo y su menú público.
/// Se crea en main.dart con el menú ya descargado, así las pantallas
/// tienen los datos desde el primer frame.
class RestaurantController extends GetxController {
  RestaurantController(RestaurantMenu menu) {
    _apply(menu);
  }

  final MenuService _menuService = MenuService();
  final CompanyService _companyService = CompanyService();

  final Rxn<Company> company = Rxn<Company>();
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isOpen = false.obs;

  Timer? _openStatusTimer;

  @override
  void onInit() {
    super.onInit();
    // Revisa cada minuto si abrió o cerró
    _openStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkIfOpen();
    });
  }

  @override
  void onClose() {
    _openStatusTimer?.cancel();
    super.onClose();
  }

  void _apply(RestaurantMenu menu) {
    company.value = menu.company;
    categories.assignAll(menu.categories);
    products.assignAll(menu.products);
    // El primer valor viene calculado por la API (en la zona horaria del restaurante)
    isOpen.value = menu.company.isOpenNow;
  }

  /// Vuelve a descargar el menú (p. ej. "jalar para refrescar")
  Future<void> refreshMenu() async {
    isLoading.value = true;
    try {
      _apply(await _menuService.getMenu(Session.slug));
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// Panel: guarda los datos de la empresa (requiere sesión)
  Future<void> updateCompany(Company updatedCompany) async {
    isLoading.value = true;
    try {
      company.value = await _companyService.updateCompany(updatedCompany);
      Get.snackbar('Éxito', 'Restaurante actualizado correctamente');
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  void checkIfOpen() {
    final c = company.value;
    if (c != null) isOpen.value = isCompanyOpen(c);
  }

  /// Misma lógica que la API: soporta horarios que pasan la medianoche
  /// (p. ej. 18:00–02:00). Sin horarios configurados = abierto.
  bool isCompanyOpen(Company company, [DateTime? at]) {
    final hours = company.businessHours;
    if (hours.isEmpty) return true;

    final now = at ?? DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final today = now.weekday;
    final yesterday = today == 1 ? 7 : today - 1;

    BusinessHours? find(int day) {
      for (final h in hours) {
        if (h.dayOfWeek == day) return h;
      }
      return null;
    }

    int toMin(String hhmm) {
      final p = hhmm.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    // Turno de hoy
    final t = find(today);
    if (t != null && !t.closed) {
      final open = toMin(t.openTime), close = toMin(t.closeTime);
      final inside = close > open
          ? minutes >= open && minutes < close
          : minutes >= open; // cierra después de medianoche
      if (inside) return true;
    }

    // Turno de ayer que sigue abierto después de medianoche
    final y = find(yesterday);
    if (y != null && !y.closed) {
      final open = toMin(y.openTime), close = toMin(y.closeTime);
      if (close <= open && minutes < close) return true;
    }
    return false;
  }
}
