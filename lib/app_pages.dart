import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/features/admin/admin_guard.dart';
import 'package:lacarta/features/admin/categories/categories_page.dart';
import 'package:lacarta/features/admin/companies_page.dart';
import 'package:lacarta/features/admin/home_pages_admin.dart';
import 'package:lacarta/features/admin/orders/orders_page.dart';
import 'package:lacarta/features/admin/payments_page.dart';
import 'package:lacarta/features/admin/products/products_page.dart';
import 'package:lacarta/features/admin/restaurant_page.dart';
import 'package:lacarta/features/admin/shell/admin_shell.dart';
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
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.admin, child: HomePagesAdmin()),
      ),
    ),
    GetPage(
      name: AppRoutes.orders,
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.orders, child: OrdersPage()),
      ),
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.products, child: ProductsPage()),
      ),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.categories, child: CategoriesPage()),
      ),
    ),
    GetPage(
      name: AppRoutes.restaurant,
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.restaurant, child: RestaurantPage()),
      ),
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const AdminGuard(
        child: AdminShell(current: AppRoutes.payments, child: PaymentsPage()),
      ),
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
