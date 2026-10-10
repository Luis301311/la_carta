import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/features/admin/admin_guard.dart';
import 'package:lacarta/features/admin/companies_page.dart';
import 'package:lacarta/features/admin/home_pages_admin.dart';
import 'package:lacarta/features/admin/orders/orders_page.dart';
import 'package:lacarta/features/admin/payments_page.dart';
import 'package:lacarta/features/auth/login_page.dart';
import 'package:lacarta/features/menu/pages/index_pages.dart';

class AppPages {
  static final pages = <GetPage>[
    // ---------- Menú público ----------
    // "/" también abre el menú (en web es la ruta por defecto)
    GetPage(
      name: AppRoutes.splash,
      page: () => const IndexPages(),
    ),
    GetPage(
      name: AppRoutes.menu,
      page: () => const IndexPages(),
    ),

    // ---------- Panel ----------
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminGuard(child: HomePagesAdmin()),
    ),
    GetPage(
      name: AppRoutes.orders,
      page: () => const AdminGuard(child: OrdersPage()),
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const AdminGuard(child: PaymentsPage()),
    ),
    GetPage(
      name: AppRoutes.companies,
      page: () => const AdminGuard(
        requireCompany: false,
        superAdminOnly: true,
        child: CompaniesPage(),
      ),
    ),
  ];
}
