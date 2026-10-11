import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/controller/company_controller.dart';

/// Color de marca del restaurante para el MENÚ DEL CLIENTE.
/// Cada restaurante lo elige en "Mi restaurante"; si no ha elegido, coral.
class MenuBrand {
  static const fallback = Color(0xFFF04432);

  /// Colores que se ofrecen en "Mi restaurante"
  static const palette = <String, Color>{
    'Coral': Color(0xFFF04432),
    'Rojo': Color(0xFFC62828),
    'Naranja': Color(0xFFE8710A),
    'Mostaza': Color(0xFFD4A017),
    'Verde': Color(0xFF2E7D32),
    'Azul': Color(0xFF1565C0),
    'Morado': Color(0xFF6A1B9A),
    'Café': Color(0xFF6D4C41),
    'Carbón': Color(0xFF17212F),
  };

  /// "#E53935" -> Color (null si no es válido)
  static Color? parse(String? hex) {
    if (hex == null) return null;
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  /// Color -> "#E53935"
  static String toHex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Color del restaurante que se está viendo
  static Color get color {
    if (!Get.isRegistered<RestaurantController>()) return fallback;
    return parse(Get.find<RestaurantController>().company.value?.primaryColor) ??
        fallback;
  }

  /// Texto/íconos encima del color (blanco o negro según qué tan claro sea)
  static Color on(Color c) =>
      c.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  static Color get onColor => on(color);
}
