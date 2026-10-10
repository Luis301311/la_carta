import 'package:flutter/material.dart';
import 'package:lacarta/core/models/product/extra_option.dart';

class CreateExtraOptionDialog extends StatefulWidget {
  /// Si viene, el diálogo edita esa opción
  final ExtraOption? initial;
  const CreateExtraOptionDialog({super.key, this.initial});

  @override
  State<CreateExtraOptionDialog> createState() =>
      _CreateExtraOptionDialogState();
}

class _CreateExtraOptionDialogState
    extends State<CreateExtraOptionDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final o = widget.initial;
    if (o != null) {
      nameController.text = o.name;
      priceController.text = o.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? "Nueva Opción" : "Editar Opción"),

      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Ingrese un nombre";
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Precio adicional",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Ingrese el precio";
                }
                final n = double.tryParse(value.trim());
                if (n == null || n < 0) return "Precio no válido";
                return null;
              },
            ),

          ],
        ),
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),

        FilledButton(
          onPressed: () {

            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              ExtraOption(
                id: widget.initial?.id,
                name: nameController.text.trim(),
                price: double.parse(priceController.text.trim()),
                isActive: widget.initial?.isActive ?? true,
              ),
            );

          },
          child: const Text("Guardar"),
        ),

      ],
    );
  }
}