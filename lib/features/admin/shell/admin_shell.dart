import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/features/admin/shell/admin_shell_controller.dart';
import 'package:lacarta/features/auth/change_password_dialog.dart';

/// Ancho desde el que se usa barra lateral en vez de barra inferior
const double kSidebarBreakpoint = 900;
const double kSidebarWidth = 240;

/// Una sección del panel
class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.route, this.label, this.icon, this.selectedIcon);
}

const _items = [
  _NavItem(AppRoutes.admin, 'Inicio', Icons.home_outlined, Icons.home),
  _NavItem(AppRoutes.orders, 'Pedidos', Icons.receipt_long_outlined, Icons.receipt_long),
  _NavItem(AppRoutes.products, 'Productos', Icons.inventory_2_outlined, Icons.inventory_2),
  _NavItem(AppRoutes.categories, 'Categorías', Icons.sell_outlined, Icons.sell),
  _NavItem(AppRoutes.payments, 'Métodos de pago', Icons.credit_card_outlined, Icons.credit_card),
  _NavItem(AppRoutes.restaurant, 'Mi restaurante', Icons.storefront_outlined, Icons.storefront),
];

/// Ir a una sección (sin acumular historial: la navegación siempre está visible)
void goToSection(String route) {
  if (Get.currentRoute == route) return;
  Get.offAllNamed(route);
}

/// Layout común del panel de la empresa:
///  - PC/tablet (≥ 900 px): barra lateral oscura a la izquierda.
///  - Celular: barra inferior (Inicio, Pedidos, Productos, Más).
/// Cada pantalla conserva su propio Scaffold/AppBar dentro.
class AdminShell extends StatelessWidget {
  final String current;
  final Widget child;
  const AdminShell({super.key, required this.current, required this.child});

  @override
  Widget build(BuildContext context) {
    // Una sola instancia para todo el panel (se reutiliza entre pantallas)
    if (!Get.isRegistered<AdminShellController>()) {
      Get.put(AdminShellController(), permanent: true);
    }
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(current: current),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(current: current),
    );
  }
}

// ------------------------------------------------------------- PC

class _Sidebar extends StatelessWidget {
  final String current;
  const _Sidebar({required this.current});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final shell = AdminShellController.to;

    return Container(
      width: kSidebarWidth,
      color: AppColors.carbon,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo + nombre del restaurante
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Row(
                children: [
                  Obx(() {
                    final logo = shell.logoUrl.value;
                    return CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.coral,
                      backgroundImage: logo != null ? NetworkImage(logo) : null,
                      child: logo == null
                          ? const Icon(Icons.storefront, color: Colors.white)
                          : null,
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Text(
                          auth.activeCompanyName.value.isEmpty
                              ? 'La Carta'
                              : auth.activeCompanyName.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        )),
                  ),
                ],
              ),
            ),

            // Secciones
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: _items
                      .map((item) => _SidebarTile(
                            item: item,
                            selected: item.route == current,
                          ))
                      .toList(),
                ),
              ),
            ),

            // Portada del restaurante (en vez de una foto fija: cada
            // restaurante ve la suya)
            Obx(() {
              final cover = shell.coverUrl.value;
              if (cover == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    cover,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
            }),

            // Usuario
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              child: Row(
                children: [
                  Obx(() {
                    final name = auth.user.value?.fullName ?? '';
                    return CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.coral,
                      child: Text(
                        name.isEmpty ? 'A' : name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(() => Text(
                          auth.user.value?.fullName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        )),
                  ),
                  IconButton(
                    tooltip: 'Cambiar contraseña',
                    icon: const Icon(Icons.key, color: Colors.white70),
                    onPressed: () => showChangePasswordDialog(context),
                  ),
                  if (auth.isSuperAdmin)
                    IconButton(
                      tooltip: 'Cambiar de empresa',
                      icon: const Icon(Icons.swap_horiz, color: Colors.white70),
                      onPressed: () => auth.leaveCompany(),
                    ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () => auth.logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _SidebarTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.coral : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => goToSection(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(selected ? item.selectedIcon : item.icon,
                    color: selected ? Colors.white : Colors.white70, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (item.route == AppRoutes.orders) const _PendingBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Globito con los pedidos por confirmar
class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final n = AdminShellController.to.pending.value;
      if (n == 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text('$n',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    });
  }
}

// ------------------------------------------------------------- Celular

class _BottomNav extends StatelessWidget {
  final String current;
  const _BottomNav({required this.current});

  /// Inicio, Pedidos y Productos tienen pestaña; el resto va en "Más"
  int get _index {
    switch (current) {
      case AppRoutes.admin:
        return 0;
      case AppRoutes.orders:
        return 1;
      case AppRoutes.products:
        return 2;
      default:
        return 3;
    }
  }

  void _showMore(BuildContext context) {
    final auth = AuthController.to;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final item in _items.skip(3))
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: item.route == current,
                selectedColor: AppColors.coralDark,
                onTap: () {
                  Navigator.pop(ctx);
                  goToSection(item.route);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Cambiar contraseña'),
              onTap: () {
                Navigator.pop(ctx);
                showChangePasswordDialog(context);
              },
            ),
            if (auth.isSuperAdmin)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Cambiar de empresa'),
                onTap: () {
                  Navigator.pop(ctx);
                  auth.leaveCompany();
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(ctx);
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pending = AdminShellController.to.pending.value;
      return NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              goToSection(AppRoutes.admin);
            case 1:
              goToSection(AppRoutes.orders);
            case 2:
              goToSection(AppRoutes.products);
            default:
              _showMore(context);
          }
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: AppColors.amber,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: AppColors.amber,
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Pedidos',
          ),
          const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Productos'),
          const NavigationDestination(
              icon: Icon(Icons.menu), label: 'Más'),
        ],
      );
    });
  }
}
