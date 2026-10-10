import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/models/company_summary.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/super_admin_service.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:lacarta/core/utils/passwords.dart';

/// Super admin: administradores de UNA empresa.
/// Agregar, desactivar/activar y restablecer contraseña.
class CompanyAdminsSheet extends StatefulWidget {
  final CompanySummary company;
  const CompanyAdminsSheet({super.key, required this.company});

  @override
  State<CompanyAdminsSheet> createState() => _CompanyAdminsSheetState();
}

class _CompanyAdminsSheetState extends State<CompanyAdminsSheet> {
  final _service = SuperAdminService();
  late Future<List<CompanyAdmin>> _future;

  String get _companyId => widget.company.id;

  @override
  void initState() {
    super.initState();
    _future = _service.listAdmins(_companyId);
  }

  void _reload() => setState(() => _future = _service.listAdmins(_companyId));

  /// Muestra las credenciales para copiarlas y enviarlas
  Future<void> _showCredentials(String email, String password) {
    final text = 'Panel de ${widget.company.name}\n'
        'Usuario: $email\nContraseña: $password';
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos de acceso'),
        content: SelectableText(text),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Listo')),
        ],
      ),
    );
  }

  Future<void> _addAdmin() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: Passwords.generate());
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo administrador'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
              ),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch((v ?? '').trim())
                    ? null
                    : 'Correo no válido',
              ),
              TextFormField(
                controller: password,
                decoration:
                    const InputDecoration(labelText: 'Contraseña inicial'),
                validator: (v) =>
                    (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.createAdmin(
        _companyId,
        fullName: name.text.trim(),
        email: email.text.trim().toLowerCase(),
        password: password.text,
      );
      _reload();
      if (mounted) {
        await _showCredentials(email.text.trim().toLowerCase(), password.text);
      }
    } on ApiException catch (e) {
      Get.snackbar('No se pudo crear', e.message);
    }
  }

  Future<void> _resetPassword(CompanyAdmin admin) async {
    final password = Passwords.generate();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Nueva contraseña para ${admin.fullName}?'),
        content: const Text(
            'Se genera una contraseña nueva y la anterior deja de servir.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Generar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.resetAdminPassword(_companyId, admin.id, password);
      if (mounted) await _showCredentials(admin.email, password);
    } on ApiException catch (e) {
      Get.snackbar('No se pudo cambiar', e.message);
    }
  }

  Future<void> _toggle(CompanyAdmin admin, bool active) async {
    try {
      await _service.setAdminActive(_companyId, admin.id, active);
      _reload();
    } on ApiException catch (e) {
      Get.snackbar('No se pudo cambiar', e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Administradores · ${widget.company.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: _addAdmin,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<CompanyAdmin>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(snap.error is ApiException
                          ? (snap.error as ApiException).message
                          : 'No se pudieron cargar'),
                    );
                  }
                  final admins = snap.data ?? [];
                  if (admins.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'Esta empresa no tiene administradores. Agrega uno para que puedan entrar a su panel.'),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: admins.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final a = admins[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: a.isActive
                              ? CustomColorBasic.yellow2
                              : CustomColorBasic.grey2,
                          child: Text(a.fullName.isEmpty
                              ? '?'
                              : a.fullName[0].toUpperCase()),
                        ),
                        title: Text(a.fullName),
                        subtitle: Text(
                          '${a.email}\n'
                          '${a.lastLoginAt == null ? 'Nunca ha entrado' : 'Último ingreso: ${Fmt.orderTime(a.lastLoginAt!)}'}'
                          '${a.isActive ? '' : ' · DESACTIVADO'}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: a.isActive
                                  ? 'Activo (puede entrar)'
                                  : 'Desactivado (no puede entrar)',
                              child: Switch(
                                value: a.isActive,
                                onChanged: (v) => _toggle(a, v),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Nueva contraseña',
                              icon: const Icon(Icons.key),
                              onPressed: () => _resetPassword(a),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
