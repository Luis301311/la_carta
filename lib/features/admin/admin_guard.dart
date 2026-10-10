import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/features/admin/companies_page.dart';
import 'package:lacarta/features/auth/login_page.dart';

/// Protege las pantallas del panel:
///  - Sin sesión → muestra el login.
///  - Super admin sin empresa escogida → muestra la lista de empresas.
///  - [superAdminOnly] → solo para el super admin.
class AdminGuard extends StatelessWidget {
  final Widget child;
  final bool requireCompany;
  final bool superAdminOnly;

  const AdminGuard({
    super.key,
    required this.child,
    this.requireCompany = true,
    this.superAdminOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    return Obx(() {
      final user = auth.user.value;
      final companyId = auth.activeCompanyId.value;

      if (user == null) return const LoginPage();
      if (superAdminOnly && !user.isSuperAdmin) {
        return const _NoAccess();
      }
      if (requireCompany && companyId == null) {
        return user.isSuperAdmin ? const CompaniesPage() : const _NoAccess();
      }
      return child;
    });
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No tienes acceso a esta sección'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => AuthController.to.logout(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
