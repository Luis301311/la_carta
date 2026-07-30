import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/features/admin/home_pages_admin.dart';
import 'package:lacarta/features/menu/pages/location_page.dart';

import '../../features/menu/pages/index_pages.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.menu,
      page: () => const IndexPages(),
    ),

    GetPage(
      name: AppRoutes.login,
      page: () => const LocationPage(),
    ),

    GetPage(
      name: AppRoutes.admin,
      page: () =>  HomePagesAdmin(),
    ),
  ];
}