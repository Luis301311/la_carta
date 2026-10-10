import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/constant/order_status.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/utils/format.dart';

/// Comprobante escogido por el cliente
class PaymentProof {
  final Uint8List bytes;
  final String name;
  PaymentProof(this.bytes, this.name);
}

/// Selector de forma de pago + datos para transferir + adjuntar comprobante.
/// Solo muestra los métodos que el restaurante tiene activos.
class PaymentSection extends StatelessWidget {
  final Company company;
  final String method;
  final ValueChanged<String> onMethodChanged;
  final double total;
  final PaymentProof? proof;
  final ValueChanged<PaymentProof?> onProofChanged;

  /// Mostrar "Adjunta el comprobante" en rojo (al intentar confirmar sin él)
  final bool showProofError;

  const PaymentSection({
    super.key,
    required this.company,
    required this.method,
    required this.onMethodChanged,
    required this.total,
    required this.proof,
    required this.onProofChanged,
    this.showProofError = false,
  });

  List<String> get _methods => [
        if (company.acceptsCash) PaymentMethod.cash,
        if (company.acceptsTransfer) PaymentMethod.transfer,
      ];

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, // las capturas no necesitan más; sube más rápido
      imageQuality: 85,
    );
    if (file == null) return;
    onProofChanged(PaymentProof(await file.readAsBytes(), file.name));
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copiado', text,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final methods = _methods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forma de pago',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        if (methods.length > 1)
          Wrap(
            spacing: 8,
            children: methods
                .map((m) => ChoiceChip(
                      avatar: Icon(PaymentMethod.icon(m), size: 18),
                      label: Text(PaymentMethod.label(m)),
                      selected: method == m,
                      onSelected: (_) => onMethodChanged(m),
                    ))
                .toList(),
          )
        else
          Row(
            children: [
              Icon(PaymentMethod.icon(method), size: 20),
              const SizedBox(width: 6),
              Text(PaymentMethod.label(method)),
            ],
          ),
        if (method == PaymentMethod.cash) ...[
          const SizedBox(height: 8),
          const Text(
            'Pagas al recibir o en caja. El restaurante confirmará tu pedido.',
            style: TextStyle(fontSize: 13, color: CustomColorBasic.grey1),
          ),
        ],
        if (method == PaymentMethod.transfer) ...[
          const SizedBox(height: 12),
          _TransferInfo(company: company, total: total, onCopy: _copy),
          const SizedBox(height: 12),
          _ProofPicker(
            proof: proof,
            onPick: _pickProof,
            onRemove: () => onProofChanged(null),
            showError: showProofError,
          ),
        ],
      ],
    );
  }
}

class _TransferInfo extends StatelessWidget {
  final Company company;
  final double total;
  final ValueChanged<String> onCopy;

  const _TransferInfo(
      {required this.company, required this.total, required this.onCopy});

  void _showQrBig(String url) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qr = company.paymentQrUrl;
    final breKey = company.breBKey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomColorBasic.white3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('Total a transferir'),
          Text(
            Fmt.money(total),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (qr != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showQrBig(qr),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  qr,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const Text('Escanéalo desde la app de tu banco (toca para ampliar)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: CustomColorBasic.grey1)),
          ],
          if (breKey != null) ...[
            const SizedBox(height: 10),
            const Text('Llave Bre-B', style: TextStyle(fontSize: 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    breKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar llave',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => onCopy(breKey),
                ),
              ],
            ),
          ],
          if (company.paymentHolder != null)
            Text('Titular: ${company.paymentHolder}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: CustomColorBasic.grey1)),
          if (company.paymentNotes != null) ...[
            const SizedBox(height: 6),
            Text(company.paymentNotes!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final PaymentProof? proof;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool showError;

  const _ProofPicker({
    required this.proof,
    required this.onPick,
    required this.onRemove,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    final p = proof;
    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                  color: showError ? Colors.red : CustomColorBasic.grey1),
            ),
            onPressed: onPick,
            icon: const Icon(Icons.upload_file),
            label: const Text('Adjuntar comprobante de pago'),
          ),
          const SizedBox(height: 4),
          Text(
            showError
                ? 'Adjunta la captura del pago para confirmar el pedido'
                : 'Después de transferir, sube la captura o pantallazo del pago',
            style: TextStyle(
                fontSize: 12,
                color: showError ? Colors.red : CustomColorBasic.grey1),
          ),
        ],
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(p.bytes, height: 70, width: 70, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Comprobante adjunto ✅',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        TextButton(onPressed: onPick, child: const Text('Cambiar')),
        IconButton(
          tooltip: 'Quitar',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
