import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/category_controller.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/core/models/product/extra_group.dart';
import 'package:lacarta/core/models/product/extra_option.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/services/storade_service.dart';
import 'package:lacarta/core/widget/admin/app_floating_button.dart';
import 'package:lacarta/features/admin/create_extra_group_dialog.dart';
import 'package:lacarta/features/admin/create_extra_option_dialog.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/services/api_client.dart';
class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final ProductController _productController = Get.put(ProductController());
  final CategoryController _categoryController = Get.put(CategoryController());
  final storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> images = [];
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final List<ExtraGroup> extraGroups = [];
  String? selectedCategory;
  bool isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Producto"),
        centerTitle: true,
      ),
      floatingActionButton: Obx(
        ()=> AppFloatingButton(
          text: "Guardar",
          icon: Icons.save,
          backgroundColor: CustomColorBasic.blue1,
          textColor: Colors.white,
          tooltip: "Guardar producto",
          onPressed: saveProduct,
          isLoading: _productController.isLoading.value,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              _sectionTitle("Información"),

              const SizedBox(height: 15),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  prefixIcon: Icon(Icons.fastfood),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Ingrese el nombre";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Precio Base",
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),
      
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Categoría",
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categoryController.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              SwitchListTile(
                value: isAvailable,
                title: const Text("Producto Disponible"),
                secondary: const Icon(Icons.check_circle),
                onChanged: (value) {
                  setState(() {
                    isAvailable = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              _buildImagesSection(),
              const SizedBox(height: 25),
              _buildExtrasSection(),
          
            ],
          ),
        ),
      ),
    );
  }



  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle("Imágenes"),

        const SizedBox(height: 15),

        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {

              if (index == 0) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Icon(Icons.add_a_photo_outlined),

                        SizedBox(height: 8),

                        Text(
                          "Agregar",
                          style: TextStyle(fontSize: 12),
                        ),

                      ],
                    ),
                  ),
                );
              }

              final image = images[index - 1];

              return Stack(
                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    right: 5,
                    top: 5,
                    child: InkWell(
                      onTap: () {

                        setState(() {
                          images.removeAt(index - 1);
                        });

                      },
                      child: const CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                ],
              );
            },
          ),
        ),

      ],
    );
  }
  Widget _buildExtrasSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      _sectionTitle("Grupos de Extras"),

      const SizedBox(height: 15),

      if (extraGroups.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(Icons.layers_outlined, size: 45),
                SizedBox(height: 10),
                Text(
                  "No hay grupos de extras",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Agrega uno para personalizar el producto.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

      ...List.generate(
        extraGroups.length,
        (groupIndex) {
          final group = extraGroups[groupIndex];

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ExpansionTile(

              leading: const Icon(Icons.layers),

              title: Text(group.title),

              subtitle: Text(
                "${group.options.length} opciones",
              ),

              childrenPadding: const EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: 15,
              ),

              children: [

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [

                    Chip(
                      label: Text(
                        group.isRequired
                            ? "Obligatorio"
                            : "Opcional",
                      ),
                    ),

                    Chip(
                      label: Text(
                        "Min ${group.minSelection}",
                      ),
                    ),

                    Chip(
                      label: Text(
                        "Max ${group.maxSelection}",
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 15),

                ...List.generate(
                  group.options.length,
                  (optionIndex) {

                    final option = group.options[optionIndex];

                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      child: ListTile(

                        title: Text(option.name),

                        subtitle: Text(
                          "\$${option.price.toStringAsFixed(0)}",
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {

                              },
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {

                                setState(() {
                                  group.options.removeAt(optionIndex);
                                });

                              },
                            ),

                          ],
                        ),
                      ),
                    );

                  },
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar opción"),
                  onPressed: () async {

                    final ExtraOption? option =
                        await showDialog<ExtraOption>(
                      context: context,
                      builder: (_) =>
                          const CreateExtraOptionDialog(),
                    );

                    if (option == null) return;

                    setState(() {
                      group.options.add(option);
                    });

                  },
                ),

                const Divider(),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Eliminar grupo",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {

                      setState(() {
                        extraGroups.removeAt(groupIndex);
                      });

                    },
                  ),
                ),

              ],
            ),
          );
        },
      ),

      const SizedBox(height: 10),

      SizedBox(
        width: 355,
        child: FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Agregar Grupo"),
          onPressed: () async {

            final ExtraGroup? group =
                await showDialog<ExtraGroup>(
              context: context,
              builder: (_) =>
                  const CreateExtraGroupDialog(),
            );

            if (group == null) return;

            setState(() {
              extraGroups.add(group);
            });

          },
        ),
      ),
      const SizedBox(height: 80),
    ],
  );
}
  Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  final bytes = await image.readAsBytes();

  setState(() {
    images.add(bytes);
  });
}


  void saveProduct() async {
    final companyId = Session.companyId;
    if (companyId == null) {
      Get.snackbar('Error', 'No hay restaurante seleccionado');
      return;
    }

    List<String> imageUrls = [];
    try {
      for (final image in images) {
        imageUrls.add(
          await storageService.uploadProductImage(image, companyId),
        );
      }
    } on ApiException catch (e) {
      // Sin sesión de admin la API responde 401 (el login es el siguiente paso)
      Get.snackbar('No se pudieron subir las imágenes', e.message);
      return;
    }

     Product newProduct = Product(
      name: nameController.text,
      description: descriptionController.text,
      basePrice: double.tryParse(priceController.text) ?? 0.0,
      categoryId: selectedCategory ?? "",
      isAvailable: isAvailable,
      imageUrl: imageUrls,
      extras: extraGroups,
    );
    _productController.createProduct(newProduct);
  }
}