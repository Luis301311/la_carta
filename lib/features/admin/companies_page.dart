import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/models/company_summary.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/super_admin_service.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/super/company_admins_sheet.dart';
import 'package:lacarta/features/admin/super/company_form_dialog.dart';
import 'package:lacarta/features/auth/change_password_dialog.dart';

/// Panel del SUPER ADMIN: todas las empresas de la plataforma.
/// Crear (con su admin), editar, suspender/reactivar, administradores,
/// eliminar y entrar al panel de cualquiera.
class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final AuthController _auth = AuthController.to;
  final _service = SuperAdminService();
  final _search = TextEditingController();

  List<CompanySummary> _companies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _companies = await _service.listCompanies(search: _search.text);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _menuLink(String slug) {
    final base = Uri.base.hasAuthority
        ? '${Uri.base.scheme}://${Uri.base.authority}'
        : 'https://tu-dominio';
    return '$base/$slug';
  }

  // ---------------------------------------------------------- acciones

  Future<void> _create() async {
    final r = await showDialog<CompanyFormResult>(
      context: context,
      builder: (_) => const CompanyFormDialog(),
    );
    if (r == null) return;
    try {
      await _service.createCompany(
        name: r.name,
        slug: r.slug,
        whatsappPhone: r.whatsappPhone,
        adminName: r.adminName,
        adminEmail: r.adminEmail,
        adminPassword: r.adminPassword,
      );
      await _load();
      if (!mounted) return;
      // Resumen para enviarle al restaurante
      final text = StringBuffer()
        ..writeln('¡Bienvenidos a La Carta, ${r.name}!')
        ..writeln()
        ..writeln('Menú para sus clientes: ${_menuLink(r.slug)}');
      if (r.adminEmail != null) {
        text
          ..writeln()
          ..writeln('Panel de administración: ${_menuLink('login')}')
          ..writeln('Usuario: ${r.adminEmail}')
          ..writeln('Contraseña: ${r.adminPassword}');
      }
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 44),
          title: Text('${r.name} quedó creada'),
          content: SelectableText(text.toString()),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar todo'),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: text.toString())),
            ),
            FilledButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Listo')),
          ],
        ),
      );
    } on ApiException catch (e) {
      // Ej.: 'El slug "x" ya está en uso', 'Ya existe un usuario con el correo…'
      Get.snackbar('No se pudo crear', e.message,
          duration: const Duration(seconds: 5));
    }
  }

  Future<void> _edit(CompanySummary c) async {
    final r = await showDialog<CompanyFormResult>(
      context: context,
      builder: (_) => CompanyFormDialog(initial: c),
    );
    if (r == null) return;
    try {
      await _service.updateCompany(c.id,
          name: r.name, slug: r.slug, whatsappPhone: r.whatsappPhone);
      Get.snackbar('Guardado', '${r.name} actualizada');
      _load();
    } on ApiException catch (e) {
      Get.snackbar('No se pudo guardar', e.message);
    }
  }

  Future<void> _toggleActive(CompanySummary c) async {
    final suspend = c.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspend ? '¿Suspender "${c.name}"?' : '¿Reactivar "${c.name}"?'),
        content: Text(suspend
            ? 'Su menú deja de mostrarse y sus administradores no podrán entrar al panel. '
                'No se borra nada; puedes reactivarla cuando quieras.'
            : 'Su menú vuelve a estar disponible y sus administradores podrán entrar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: suspend ? Colors.orange : Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(suspend ? 'Suspender' : 'Reactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.setActive(c.id, !suspend);
      _load();
    } on ApiException catch (e) {
      Get.snackbar('No se pudo cambiar', e.message);
    }
  }

  Future<void> _delete(CompanySummary c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteCompanyDialog(company: c),
    );
    if (ok != true) return;
    try {
      await _service.deleteCompany(c.id);
      Get.snackbar('Eliminada', '${c.name} se eliminó');
      _load();
    } on ApiException catch (e) {
      Get.snackbar('No se pudo eliminar', e.message);
    }
  }

  void _admins(CompanySummary c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: CompanyAdminsSheet(company: c),
      ),
    );
  }

  // ---------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final active = _companies.where((c) => c.isActive).length;
    final suspended = _companies.length - active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas · Super admin'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Cambiar contraseña',
            icon: const Icon(Icons.key),
            onPressed: () => showChangePasswordDialog(context),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Nueva empresa'),
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar por nombre o slug…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _load,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_companies.length} empresas · $active activas'
                    '${suspended > 0 ? ' · $suspended suspendidas' : ''}',
                    style: const TextStyle(color: CustomColorBasic.grey1),
                  ),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_companies.isEmpty) {
      return Center(
        child: Text(_search.text.isEmpty
            ? 'Aún no hay empresas. Crea la primera con "Nueva empresa".'
            : 'Ninguna empresa coincide con la búsqueda'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: _companies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _companyCard(_companies[i]),
      ),
    );
  }

  Widget _companyCard(CompanySummary c) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      c.isActive ? CustomColorBasic.yellow2 : CustomColorBasic.grey2,
                  backgroundImage:
                      c.logoUrl != null ? NetworkImage(c.logoUrl!) : null,
                  child: c.logoUrl == null
                      ? const Icon(Icons.storefront, color: CustomColorBasic.black1)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('/${c.slug}',
                          style: const TextStyle(color: CustomColorBasic.grey1)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (c.isActive ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.isActive ? 'Activa' : 'Suspendida',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: c.isActive
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _edit(c);
                      case 'admins':
                        _admins(c);
                      case 'link':
                        Clipboard.setData(ClipboardData(text: _menuLink(c.slug)));
                        Get.snackbar('Copiado', _menuLink(c.slug));
                      case 'toggle':
                        _toggleActive(c);
                      case 'delete':
                        _delete(c);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar nombre, slug y WhatsApp')),
                    ),
                    const PopupMenuItem(
                      value: 'admins',
                      child: ListTile(
                          leading: Icon(Icons.manage_accounts),
                          title: Text('Administradores')),
                    ),
                    const PopupMenuItem(
                      value: 'link',
                      child: ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Copiar enlace del menú')),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(c.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline),
                        title: Text(c.isActive ? 'Suspender' : 'Reactivar'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: AppColors.danger),
                        title: Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _stat(Icons.category, '${c.categories} categorías'),
                      _stat(Icons.fastfood, '${c.products} productos'),
                      _stat(Icons.receipt_long, '${c.orders} pedidos'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _auth.selectCompany(c.id, c.name),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text) => Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: 16),
        label: Text(text, style: const TextStyle(fontSize: 12)),
      );
}
