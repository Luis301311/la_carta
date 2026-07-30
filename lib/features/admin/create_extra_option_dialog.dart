import 'package:flutter/material.dart';
import 'package:lacarta/core/models/product/extra_option.dart';

class CreateExtraOptionDialog extends StatefulWidget {
  const CreateExtraOptionDialog({super.key});

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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Opción"),

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
                if (value == null || value.isEmpty) {
                  return "Ingrese el precio";
                }
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
                name: nameController.text,
                price: double.parse(priceController.text),
              ),
            );

          },
          child: const Text("Guardar"),
        ),

      ],
    );
  }
}