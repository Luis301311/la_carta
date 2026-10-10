import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:lacarta/app_pages.dart';
import 'package:lacarta/config/api_config.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/controller/cart_controller.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/controller/order_controller.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/menu_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El restaurante sale de la URL: lacarta.app/burger_house
  // (en desarrollo, sin slug en la URL, se usa ApiConfig.defaultSlug)
  final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
  Session.slug = segments.isNotEmpty ? segments.first : ApiConfig.defaultSlug;

  // Sesión del panel guardada en el dispositivo (si la hay)
  final auth = Get.put(AuthController(), permanent: true);
  await auth.restore();

  try {
    // Una sola petición trae empresa, horario, categorías y productos
    final menu = await MenuService().getMenu(Session.slug);
    Session.companyId = menu.company.id;

    Get.put(RestaurantController(menu), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);

    runApp(const MyApp());
  } on ApiException catch (e) {
    // Si lo que se abrió es el panel (/#/login, /#/admin...), no hace falta
    // el menú público: se arranca la app igual.
    final route = Uri.base.fragment;
    if (route.startsWith(AppRoutes.login) || route.startsWith(AppRoutes.admin)) {
      runApp(const MyApp());
      return;
    }
    runApp(ErrorApp(
      message: e.statusCode == 404
          ? 'No encontramos el restaurante "${Session.slug}".'
          : e.message,
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "La Carta",
      debugShowCheckedModeBanner: false,
      // Paleta de La Carta (coral, crema, carbón, verde) con Poppins
      theme: AppTheme.light(),
      initialRoute: AppRoutes.menu,
      getPages: AppPages.pages,
    );
  }
}

/// Pantalla cuando el menú no se pudo cargar (slug inválido, API apagada...)
class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
