import 'package:flutter/material.dart';
import 'package:lacarta/core/models/product/extra_group.dart';

class CreateExtraGroupDialog extends StatefulWidget {
  const CreateExtraGroupDialog({super.key});

  @override
  State<CreateExtraGroupDialog> createState() =>
      _CreateExtraGroupDialogState();
}

class _CreateExtraGroupDialogState
    extends State<CreateExtraGroupDialog> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();

  bool isRequired = false;

  int minSelection = 0;
  int maxSelection = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nuevo Grupo"),

      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Nombre del grupo",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese un nombre";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Obligatorio"),
                value: isRequired,
                onChanged: (value) {
                  setState(() {
                    isRequired = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [

                  Expanded(
                    child: TextFormField(
                      initialValue: "$minSelection",
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Mínimo",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        minSelection =
                            int.tryParse(value) ?? 0;
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextFormField(
                      initialValue: "$maxSelection",
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Máximo",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        maxSelection =
                            int.tryParse(value) ?? 1;
                      },
                    ),
                  ),

                ],
              ),

            ],
          ),
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
              ExtraGroup(
                title: titleController.text,
                isRequired: isRequired,
                minSelection: minSelection,
                maxSelection: maxSelection,
                options: [],
              ),
            );
          },
          child: const Text("Guardar"),
        ),

      ],
    );
  }
}