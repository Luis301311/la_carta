import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';

/// Flecha de "volver" para las pantallas del panel.
///
/// La flecha automática de Flutter solo aparece si hay una pantalla anterior.
/// En web, al recargar o entrar directo por URL (p. ej. /#/admin/orders) no hay
/// historial y la flecha desaparecía. Esta siempre se muestra: vuelve atrás si
/// se puede y, si no, va a [fallbackRoute] (el inicio del panel).
class SmartBackButton extends StatelessWidget {
  final String fallbackRoute;
  const SmartBackButton({super.key, this.fallbackRoute = AppRoutes.admin});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Volver',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          Get.offAllNamed(fallbackRoute);
        }
      },
    );
  }
}
