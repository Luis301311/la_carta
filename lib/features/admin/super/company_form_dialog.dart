import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:lacarta/core/models/company_summary.dart';
import 'package:lacarta/core/utils/passwords.dart';

/// Lo que devuelve el formulario
class CompanyFormResult {
  final String name;
  final String slug;
  final String? whatsappPhone;
  // Solo al crear
  final String? adminName;
  final String? adminEmail;
  final String? adminPassword;

  CompanyFormResult({
    required this.name,
    required this.slug,
    this.whatsappPhone,
    this.adminName,
    this.adminEmail,
    this.adminPassword,
  });
}

/// Crear empresa (con su administrador) o editar nombre, slug y WhatsApp.
class CompanyFormDialog extends StatefulWidget {
  final CompanySummary? initial;
  const CompanyFormDialog({super.key, this.initial});

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _slug = TextEditingController(text: widget.initial?.slug ?? '');
  late final _whatsapp =
      TextEditingController(text: widget.initial?.whatsappPhone ?? '');
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController(text: Passwords.generate());

  /// Mientras no lo toquen a mano, el slug se arma solo con el nombre
  bool _slugTouched = false;
  bool _withAdmin = true;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _slugTouched = _isEdit;
  }

  @override
  void dispose() {
    for (final c in [_name, _slug, _whatsapp, _adminName, _adminEmail, _adminPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _normalizeWhatsapp(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return null;
    if (d.length == 10 && d.startsWith('3')) d = '57$d';
    return d;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final withAdmin = !_isEdit && _withAdmin;
    Navigator.pop(
      context,
      CompanyFormResult(
        name: _name.text.trim(),
        slug: _slug.text.trim(),
        whatsappPhone: _normalizeWhatsapp(_whatsapp.text),
        adminName: withAdmin ? _adminName.text.trim() : null,
        adminEmail: withAdmin ? _adminEmail.text.trim().toLowerCase() : null,
        adminPassword: withAdmin ? _adminPassword.text : null,
      ),
    );
  }

  InputDecoration _deco(String label, {String? hint, String? helper, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        suffixIcon: suffix,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar empresa' : 'Nueva empresa'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.words,
                  decoration: _deco('Nombre del restaurante', hint: 'Ej.: Pizzería Don Tito'),
                  onChanged: (v) {
                    if (!_slugTouched) {
                      setState(() => _slug.text = Slug.fromName(v));
                    }
                  },
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slug,
                  decoration: _deco('Enlace (slug)',
                      helper: _isEdit
                          ? 'Ojo: si lo cambias, el enlace y los QR que ya repartieron dejan de funcionar.'
                          : 'Así queda el enlace del menú: tudominio.com/${_slug.text.isEmpty ? 'slug' : _slug.text}'),
                  onChanged: (_) => setState(() => _slugTouched = true),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Escribe el slug';
                    if (!Slug.valid.hasMatch(t)) {
                      return 'Solo minúsculas, números, - o _ (sin espacios ni tildes)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: _deco('WhatsApp para pedidos (opcional)',
                      hint: '300 123 4567'),
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (d.isEmpty) return null;
                    return d.length < 10 || d.length > 15 ? 'Número no válido' : null;
                  },
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Crear también su administrador'),
                    value: _withAdmin,
                    onChanged: (v) => setState(() => _withAdmin = v),
                  ),
                  if (_withAdmin) ...[
                    TextFormField(
                      controller: _adminName,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco('Nombre del administrador'),
                      validator: (v) =>
                          (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _deco('Correo para iniciar sesión'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                            ? null
                            : 'Correo no válido';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminPassword,
                      decoration: _deco(
                        'Contraseña inicial',
                        helper: 'Envíasela al restaurante; luego puede cambiarla.',
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Generar otra',
                              icon: const Icon(Icons.refresh),
                              onPressed: () => setState(
                                  () => _adminPassword.text = Passwords.generate()),
                            ),
                            IconButton(
                              tooltip: 'Copiar',
                              icon: const Icon(Icons.copy),
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: _adminPassword.text)),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Guardar' : 'Crear empresa'),
        ),
      ],
    );
  }
}

/// Diálogo de "Escribe el slug para confirmar" antes de borrar todo
class DeleteCompanyDialog extends StatefulWidget {
  final CompanySummary company;
  const DeleteCompanyDialog({super.key, required this.company});

  @override
  State<DeleteCompanyDialog> createState() => _DeleteCompanyDialogState();
}

class _DeleteCompanyDialogState extends State<DeleteCompanyDialog> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    final ok = _confirm.text.trim() == c.slug;
    return AlertDialog(
      title: Text('¿Eliminar "${c.name}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se borran para siempre su menú (${c.categories} categorías, ${c.products} productos), '
            'sus ${c.orders} pedidos y sus administradores. Esto no se puede deshacer.\n\n'
            'Si solo quieres que deje de funcionar por un tiempo, mejor suspéndela.',
          ),
          const SizedBox(height: 14),
          Text('Para confirmar, escribe: ${c.slug}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _confirm,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: ok ? () => Navigator.pop(context, true) : null,
          child: const Text('Eliminar para siempre'),
        ),
      ],
    );
  }
}
