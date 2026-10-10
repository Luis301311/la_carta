import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/company_service.dart';
import 'package:lacarta/core/services/storade_service.dart';
import 'package:lacarta/core/widget/responsive.dart';

/// Panel: cómo cobra el restaurante (sin pasarela).
/// Efectivo y/o transferencia por QR o llave Bre-B.
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _service = CompanyService();
  final _storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _key = TextEditingController();
  final _holder = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingQr = false;
  String? _loadError;

  bool _acceptsCash = true;
  bool _acceptsTransfer = false;
  String? _qrUrl;

  String get _companyId => AuthController.to.activeCompanyId.value!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _key.dispose();
    _holder.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final c = await _service.getCompany(_companyId);
      _acceptsCash = c.acceptsCash;
      _acceptsTransfer = c.acceptsTransfer;
      _key.text = c.breBKey ?? '';
      _holder.text = c.paymentHolder ?? '';
      _notes.text = c.paymentNotes ?? '';
      _qrUrl = c.paymentQrUrl;
    } on ApiException catch (e) {
      _loadError = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickQr() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file == null) return;
    setState(() => _uploadingQr = true);
    try {
      final url = await _storage.uploadProductImage(
        await file.readAsBytes(),
        _companyId,
        filename: file.name,
      );
      setState(() => _qrUrl = url);
    } on ApiException catch (e) {
      Get.snackbar('No se pudo subir el QR', e.message);
    } finally {
      if (mounted) setState(() => _uploadingQr = false);
    }
  }

  Future<void> _save() async {
    if (!_acceptsCash && !_acceptsTransfer) {
      Get.snackbar('Falta un método', 'Activa al menos efectivo o transferencia');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_acceptsTransfer && _key.text.trim().isEmpty && _qrUrl == null) {
      Get.snackbar('Faltan datos',
          'Para recibir transferencias agrega la llave Bre-B o la imagen del QR');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.patchCompany(_companyId, {
        'acceptsCash': _acceptsCash,
        'acceptsTransfer': _acceptsTransfer,
        // '' = borrar el dato
        'breBKey': _key.text.trim(),
        'paymentHolder': _holder.text.trim(),
        'paymentNotes': _notes.text.trim(),
        'paymentQrUrl': _qrUrl ?? '',
      });
      Get.snackbar('Guardado', 'Los métodos de pago quedaron actualizados');
    } on ApiException catch (e) {
      Get.snackbar('No se pudo guardar', e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Métodos de pago')),
      body: ResponsiveCenter(
        maxWidth: 640,
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
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Sin pasarela de pago: el cliente transfiere desde la app de '
                          'su banco, adjunta la captura y tú confirmas el pago en Pedidos.',
                          style: TextStyle(color: CustomColorBasic.grey1),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                secondary: const Icon(Icons.payments_outlined),
                                title: const Text('Efectivo'),
                                subtitle:
                                    const Text('Paga al recibir o en caja'),
                                value: _acceptsCash,
                                onChanged: (v) =>
                                    setState(() => _acceptsCash = v),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                secondary: const Icon(Icons.qr_code_2),
                                title: const Text('Transferencia (QR / Bre-B)'),
                                subtitle: const Text(
                                    'El cliente debe adjuntar el comprobante'),
                                value: _acceptsTransfer,
                                onChanged: (v) =>
                                    setState(() => _acceptsTransfer = v),
                              ),
                            ],
                          ),
                        ),
                        if (_acceptsTransfer) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Datos para transferir',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _key,
                                    decoration: const InputDecoration(
                                      labelText: 'Llave Bre-B',
                                      hintText:
                                          'Celular, cédula, correo o @alias',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) => (v ?? '').length > 80
                                        ? 'Máximo 80 caracteres'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _holder,
                                    decoration: const InputDecoration(
                                      labelText: 'Titular de la cuenta',
                                      hintText:
                                          'Para que el cliente verifique antes de pagar',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _notes,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Indicaciones (opcional)',
                                      hintText:
                                          'Ej.: También recibimos Nequi 300 123 4567',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Código QR de cobro'),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Descárgalo desde la app de tu banco y súbelo aquí.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: CustomColorBasic.grey1),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_qrUrl != null)
                                    Center(
                                      child: Image.network(
                                        _qrUrl!,
                                        height: 180,
                                        errorBuilder: (_, __, ___) =>
                                            const Text(
                                                'No se pudo cargar la imagen'),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed:
                                            _uploadingQr ? null : _pickQr,
                                        icon: _uploadingQr
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Icon(Icons.upload),
                                        label: Text(_qrUrl == null
                                            ? 'Subir QR'
                                            : 'Cambiar QR'),
                                      ),
                                      if (_qrUrl != null)
                                        TextButton(
                                          onPressed: () =>
                                              setState(() => _qrUrl = null),
                                          child: const Text('Quitar QR'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.carbon,
                              foregroundColor: CustomColorBasic.white1,
                            ),
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: CustomColorBasic.white1),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
