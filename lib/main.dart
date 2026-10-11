import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
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
import 'package:lacarta/features/menu/pages/index_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URLs limpias: lacarta.app/burger_house y lacarta.app/admin/orders (sin "#").
  // El hosting debe redirigir todas las rutas a index.html (render.yaml lo hace).
  usePathUrlStrategy();

  // ¿Qué se abrió? El primer tramo de la URL decide:
  //  /admin/... o /login  -> panel (no necesita cargar ningún menú)
  //  /burger_house        -> menú de ese restaurante
  //  /                    -> en desarrollo, ApiConfig.defaultSlug
  const panelSegments = {'admin', 'login'};
  final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
  final first = segments.isNotEmpty ? segments.first : null;
  final isPanel = first != null && panelSegments.contains(first);
  Session.slug = (first != null && !isPanel && first != 'menu')
      ? first
      : ApiConfig.defaultSlug;

  // Sesión del panel guardada en el dispositivo (si la hay)
  final auth = Get.put(AuthController(), permanent: true);
  await auth.restore();

  if (isPanel) {
    runApp(const MyApp());
    return;
  }
  if (Session.slug.isEmpty) {
    // Producción, raíz del sitio sin restaurante
    runApp(const ErrorApp(
      message: 'Abre el enlace o escanea el código QR de tu restaurante para ver su menú.',
    ));
    return;
  }

  try {
    // Una sola petición trae empresa, horario, categorías y productos
    final menu = await MenuService().getMenu(Session.slug);
    Session.companyId = menu.company.id;

    Get.put(RestaurantController(menu), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);

    runApp(const MyApp());
  } on ApiException catch (e) {
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
      // /burger_house (o cualquier ruta que no sea del panel) -> el menú
      unknownRoute: GetPage(name: '/menu-slug', page: () => const IndexPages()),
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
