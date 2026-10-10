import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/company_service.dart';
import 'package:lacarta/core/services/storade_service.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/shell/admin_shell_controller.dart';

/// Panel: datos del restaurante que ve el cliente en el menú.
/// Logo, portada, contacto, WhatsApp, ubicación en el mapa y horario.
class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

/// Horario editable de un día
class _Day {
  final int dayOfWeek;
  bool closed;
  TimeOfDay open;
  TimeOfDay close;
  _Day(this.dayOfWeek, this.closed, this.open, this.close);
}

class _RestaurantPageState extends State<RestaurantPage> {
  final _service = CompanyService();
  final _storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _taxId = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _uploading; // 'logo' | 'cover'

  Company? _company;
  String? _logoUrl;
  String? _coverUrl;
  LatLng? _point;
  late List<_Day> _days;

  /// Centro por defecto del mapa (Valledupar)
  static const _defaultCenter = LatLng(10.4631, -73.2532);

  static const _dayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  String get _companyId => AuthController.to.activeCompanyId.value!;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) => _Day(i + 1, false,
        const TimeOfDay(hour: 11, minute: 0), const TimeOfDay(hour: 22, minute: 0)));
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _taxId, _phone, _whatsapp, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  static TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final c = await _service.getCompany(_companyId);
      _company = c;
      _name.text = c.name;
      _taxId.text = c.taxId ?? '';
      _phone.text = c.phone;
      _whatsapp.text = c.whatsappPhone ?? '';
      _email.text = c.email ?? '';
      _address.text = c.location.address;
      _logoUrl = c.logoUrl.isEmpty ? null : c.logoUrl;
      _coverUrl = c.coverUrl;
      _point = c.location.hasCoordinates
          ? LatLng(c.location.lat!, c.location.lng!)
          : null;
      // Días sin horario guardado = cerrados (si no hay ninguno, 11:00–22:00)
      if (c.businessHours.isNotEmpty) {
        final byDay = {for (final h in c.businessHours) h.dayOfWeek: h};
        _days = List.generate(7, (i) {
          final h = byDay[i + 1];
          return h == null
              ? _Day(i + 1, true, const TimeOfDay(hour: 11, minute: 0),
                  const TimeOfDay(hour: 22, minute: 0))
              : _Day(i + 1, h.closed, _parse(h.openTime), _parse(h.closeTime));
        });
      }
    } on ApiException catch (e) {
      _loadError = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(String which) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: which == 'cover' ? 1600 : 800,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = which);
    try {
      final url = await _storage.uploadProductImage(
        await file.readAsBytes(),
        _companyId,
        filename: file.name,
      );
      setState(() {
        if (which == 'logo') {
          _logoUrl = url;
        } else {
          _coverUrl = url;
        }
      });
    } on ApiException catch (e) {
      Get.snackbar('No se pudo subir la imagen', e.message);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _pickTime(_Day d, bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? d.open : d.close,
      helpText: '${_dayNames[d.dayOfWeek - 1]} · ${isOpen ? 'abre' : 'cierra'}',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        d.open = picked;
      } else {
        d.close = picked;
      }
    });
  }

  /// Copia el horario del lunes a todos los días
  void _copyMondayToAll() {
    final m = _days.first;
    setState(() {
      for (final d in _days.skip(1)) {
        d.closed = m.closed;
        d.open = m.open;
        d.close = m.close;
      }
    });
  }

  /// "300 123 4567" -> "573001234567"
  static String? _normalizeWhatsapp(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 10 && digits.startsWith('3')) digits = '57$digits';
    return digits;
  }

  String? _nullIfEmpty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // 1) Datos. Los vacíos van como null (así la API los borra y no
      //    falla validando, p. ej., un correo vacío)
      final updated = await _service.patchCompany(_companyId, {
        'name': _name.text.trim(),
        'taxId': _nullIfEmpty(_taxId),
        'phone': _nullIfEmpty(_phone),
        'whatsappPhone': _normalizeWhatsapp(_whatsapp.text),
        'email': _nullIfEmpty(_email),
        'address': _nullIfEmpty(_address),
        'latitude': _point?.latitude,
        'longitude': _point?.longitude,
        'logoUrl': _logoUrl,
        'coverUrl': _coverUrl,
      });
      // 2) Horario
      await _service.setHours(
        _companyId,
        _days
            .map((d) => BusinessHours(
                  dayOfWeek: d.dayOfWeek,
                  openTime: _fmt(d.open),
                  closeTime: _fmt(d.close),
                  closed: d.closed,
                ))
            .toList(),
      );
      _company = updated;
      await AuthController.to.renameActiveCompany(updated.name);
      if (Get.isRegistered<AdminShellController>()) {
        AdminShellController.to.reloadBranding();
      }
      _whatsapp.text = updated.whatsappPhone ?? '';
      Get.snackbar('Guardado', 'Los datos del restaurante quedaron actualizados');
    } on ApiException catch (e) {
      Get.snackbar('No se pudo guardar', e.message,
          duration: const Duration(seconds: 5));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------- UI

  Widget _section(String title, IconData icon, List<Widget> children,
      {String? subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.coral),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: CustomColorBasic.grey1)),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _imagesSection() {
    final cover = _coverUrl;
    final logo = _logoUrl;
    return _section('Imagen del menú', Icons.image_outlined, [
      // Portada con el logo encima, como se verá en el menú
      SizedBox(
        height: 190,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                color: CustomColorBasic.white3,
                child: cover == null
                    ? const Center(
                        child: Text('Sin portada',
                            style: TextStyle(color: Colors.grey)))
                    : Image.network(cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image)),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 0,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: CustomColorBasic.white3,
                  backgroundImage: logo != null ? NetworkImage(logo) : null,
                  child: logo == null
                      ? const Icon(Icons.storefront, size: 32)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _uploading != null ? null : () => _pickImage('logo'),
            icon: _uploading == 'logo'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.account_circle_outlined),
            label: Text(logo == null ? 'Subir logo' : 'Cambiar logo'),
          ),
          OutlinedButton.icon(
            onPressed: _uploading != null ? null : () => _pickImage('cover'),
            icon: _uploading == 'cover'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.panorama_outlined),
            label: Text(cover == null ? 'Subir portada' : 'Cambiar portada'),
          ),
          if (cover != null)
            TextButton(
              onPressed: () => setState(() => _coverUrl = null),
              child: const Text('Quitar portada'),
            ),
        ],
      ),
    ]);
  }

  Widget _dataSection() {
    InputDecoration deco(String label, IconData icon, {String? hint, String? helper}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        );

    return _section('Datos', Icons.storefront_outlined, [
      TextFormField(
        controller: _name,
        decoration: deco('Nombre del restaurante', Icons.storefront),
        validator: (v) =>
            (v ?? '').trim().length < 2 ? 'Escribe el nombre' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _whatsapp,
        keyboardType: TextInputType.phone,
        decoration: deco('WhatsApp para pedidos', Icons.chat,
            hint: '300 123 4567',
            helper: 'Aquí llegan los pedidos. Se agrega el 57 automáticamente.'),
        validator: (v) {
          final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
          if (d.isEmpty) return null;
          if (d.length < 10 || d.length > 15) return 'Número no válido';
          return null;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: deco('Teléfono (opcional)', Icons.phone),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: deco('Correo (opcional)', Icons.mail_outline),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return null;
          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
              ? null
              : 'Correo no válido';
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _taxId,
        decoration: deco('NIT (opcional)', Icons.badge_outlined),
      ),
    ]);
  }

  Widget _locationSection() {
    final point = _point;
    return _section('Ubicación', Icons.place_outlined, [
      TextFormField(
        controller: _address,
        decoration: const InputDecoration(
          labelText: 'Dirección',
          hintText: 'Ej.: Cra 9 # 16-50, Valledupar',
          prefixIcon: Icon(Icons.home_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            key: const ValueKey('restaurant-map'),
            options: MapOptions(
              initialCenter: point ?? _defaultCenter,
              initialZoom: point == null ? 13 : 16,
              // Tocar el mapa pone el pin
              onTap: (_, latLng) => setState(() => _point = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lacarta.app',
              ),
              // Siempre presente; sin pin, la lista de marcadores va vacía
              MarkerLayer(markers: [
                if (point != null)
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: AppColors.danger, size: 40),
                  ),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: Text(
              point == null
                  ? 'Toca el mapa para marcar dónde queda el restaurante.'
                  : 'Pin: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              style:
                  const TextStyle(fontSize: 12, color: CustomColorBasic.grey1),
            ),
          ),
          if (point != null)
            TextButton(
              onPressed: () => setState(() => _point = null),
              child: const Text('Quitar pin'),
            ),
        ],
      ),
    ]);
  }

  Widget _hoursSection() {
    return _section(
      'Horario',
      Icons.schedule,
      subtitle:
          'Si la hora de cierre es menor que la de apertura (p. ej. 18:00 a 02:00), se entiende que cierra al día siguiente.',
      [
        ..._days.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(_dayNames[d.dayOfWeek - 1],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: !d.closed,
                    onChanged: (v) => setState(() => d.closed = !v),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: d.closed
                        ? const Text('Cerrado',
                            style: TextStyle(color: Colors.grey))
                        : Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              OutlinedButton(
                                onPressed: () => _pickTime(d, true),
                                child: Text(_fmt(d.open)),
                              ),
                              const Text('a'),
                              OutlinedButton(
                                onPressed: () => _pickTime(d, false),
                                child: Text(_fmt(d.close)),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _copyMondayToAll,
            icon: const Icon(Icons.copy_all),
            label: const Text('Copiar el horario del lunes a todos los días'),
          ),
        ),
      ],
    );
  }

  Widget _linkSection() {
    final slug = _company?.slug ?? '';
    if (slug.isEmpty) return const SizedBox.shrink();
    // En web toma el dominio desde donde se abrió el panel
    final base = Uri.base.hasAuthority
        ? '${Uri.base.scheme}://${Uri.base.authority}'
        : 'https://tu-dominio';
    final link = '$base/$slug';
    return _section('Enlace del menú', Icons.link, [
      SelectableText(link, style: const TextStyle(fontSize: 15)),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: link));
            Get.snackbar('Copiado', link);
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar enlace'),
        ),
      ),
    ],
        subtitle:
            'Compártelo o ponlo en un código QR en las mesas. El nombre del enlace solo lo cambia el administrador de la plataforma.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi restaurante')),
      floatingActionButton: _loading || _loadError != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving || _uploading != null ? null : _save,
              backgroundColor: AppColors.carbon,
              foregroundColor: Colors.white,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
      body: ResponsiveCenter(
        maxWidth: 760,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        TextButton(
                            onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    // SingleChildScrollView (no ListView): ListView destruye y
                    // recrea lo que sale de pantalla, y eso rompe el mapa
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _imagesSection(),
                          _dataSection(),
                          _locationSection(),
                          _hoursSection(),
                          _linkSection(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
