import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/core/widget/smart_back_button.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/controller/category_controller.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/core/models/product/extra_group.dart';
import 'package:lacarta/core/models/product/extra_option.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/storade_service.dart';
import 'package:lacarta/core/widget/admin/app_floating_button.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/create_extra_group_dialog.dart';
import 'package:lacarta/features/admin/create_extra_option_dialog.dart';

/// Crear o editar un producto (si viene [product], es edición).
/// Al guardar con éxito cierra la pantalla devolviendo `true`.
class CreateProductPage extends StatefulWidget {
  final Product? product;
  const CreateProductPage({super.key, this.product});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

/// Imagen nueva escogida en el dispositivo (aún no subida)
class _NewImage {
  final Uint8List bytes;
  final String name;
  _NewImage(this.bytes, this.name);
}

class _CreateProductPageState extends State<CreateProductPage> {
  // Instancias del panel (tag 'admin'), separadas de las del menú público
  final ProductController _productController =
      Get.put(ProductController(admin: true), tag: 'admin');
  final CategoryController _categoryController =
      Get.put(CategoryController(admin: true), tag: 'admin');
  final storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  /// Fotos que ya tenía el producto (URLs) + fotos nuevas por subir
  final List<String> existingImages = [];
  final List<_NewImage> images = [];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final List<ExtraGroup> extraGroups = [];
  String? selectedCategory;
  bool isAvailable = true;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      nameController.text = p.name;
      descriptionController.text = p.description;
      priceController.text = p.basePrice.toStringAsFixed(0);
      selectedCategory = p.categoryId;
      isAvailable = p.isAvailable;
      existingImages.addAll(p.imageUrl);
      // Copias: si se cancela la edición, el producto de la lista no cambia
      extraGroups.addAll(p.extras.map((g) => ExtraGroup(
            id: g.id,
            title: g.title,
            isRequired: g.isRequired,
            minSelection: g.minSelection,
            maxSelection: g.maxSelection,
            options: g.options.toList(),
          )));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(fallbackRoute: AppRoutes.products),
        title: Text(_isEdit ? "Editar producto" : "Nuevo producto"),
        centerTitle: true,
      ),
      floatingActionButton: AppFloatingButton(
        text: "Guardar",
        icon: Icons.save,
        backgroundColor: AppColors.carbon,
        textColor: Colors.white,
        tooltip: "Guardar producto",
        onPressed: _saving ? null : saveProduct,
        isLoading: _saving,
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: SingleChildScrollView(
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
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? "Ingrese el nombre"
                      : null,
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
                  validator: (value) {
                    final n = double.tryParse((value ?? '').trim());
                    if (n == null) return "Ingrese el precio (solo números)";
                    if (n < 0) return "El precio no puede ser negativo";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Obx: las categorías pueden llegar después de abrir la pantalla
                Obx(() {
                  final cats = _categoryController.categories.toList();
                  final exists = cats.any((c) => c.id == selectedCategory);
                  return DropdownButtonFormField<String>(
                    // Solo si existe en la lista (si no, Flutter lanza un error)
                    initialValue: exists ? selectedCategory : null,
                    decoration: InputDecoration(
                      labelText: "Categoría",
                      prefixIcon: const Icon(Icons.category),
                      border: const OutlineInputBorder(),
                      helperText: cats.isEmpty
                          ? 'Primero crea una categoría en "Categorías"'
                          : null,
                    ),
                    items: cats
                        .map((category) => DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.isActive
                                  ? category.name
                                  : '${category.name} (inactiva)'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                    validator: (value) =>
                        value == null ? "Escoge una categoría" : null,
                  );
                }),

                const SizedBox(height: 15),
                SwitchListTile(
                  value: isAvailable,
                  title: const Text("Producto disponible"),
                  subtitle: Text(isAvailable
                      ? 'Se muestra en el menú'
                      : 'Agotado: no aparece en el menú'),
                  secondary: const Icon(Icons.check_circle),
                  onChanged: (value) => setState(() => isAvailable = value),
                ),
                const SizedBox(height: 25),
                _buildImagesSection(),
                const SizedBox(height: 25),
                _buildExtrasSection(),
              ],
            ),
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
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _removeBadge(VoidCallback onTap) {
    return Positioned(
      right: 5,
      top: 5,
      child: InkWell(
        onTap: onTap,
        child: const CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.danger,
          child: Icon(Icons.close, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    final total = existingImages.length + images.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Imágenes"),
        const SizedBox(height: 15),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: total + 1,
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
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined),
                        SizedBox(height: 8),
                        Text("Agregar", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              final i = index - 1;
              // Primero las fotos que ya tenía, luego las nuevas
              if (i < existingImages.length) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        existingImages[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    _removeBadge(
                        () => setState(() => existingImages.removeAt(i))),
                  ],
                );
              }

              final j = i - existingImages.length;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      images[j].bytes,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  _removeBadge(() => setState(() => images.removeAt(j))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editGroup(int groupIndex) async {
    final ExtraGroup? edited = await showDialog<ExtraGroup>(
      context: context,
      builder: (_) =>
          CreateExtraGroupDialog(initial: extraGroups[groupIndex]),
    );
    if (edited == null) return;
    setState(() => extraGroups[groupIndex] = edited);
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Grupos de Extras"),
        const SizedBox(height: 15),
        if (extraGroups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
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
          ),
        ...List.generate(extraGroups.length, (groupIndex) {
          final group = extraGroups[groupIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ExpansionTile(
              leading: const Icon(Icons.layers),
              title: Text(group.title),
              subtitle: Text("${group.options.length} opciones"),
              childrenPadding:
                  const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                        label: Text(
                            group.isRequired ? "Obligatorio" : "Opcional")),
                    Chip(label: Text("Min ${group.minSelection}")),
                    Chip(label: Text("Max ${group.maxSelection}")),
                  ],
                ),
                const SizedBox(height: 15),
                ...List.generate(group.options.length, (optionIndex) {
                  final option = group.options[optionIndex];
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    child: ListTile(
                      title: Text(option.name),
                      subtitle: Text("\$${option.price.toStringAsFixed(0)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar opción',
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final ExtraOption? edited =
                                  await showDialog<ExtraOption>(
                                context: context,
                                builder: (_) =>
                                    CreateExtraOptionDialog(initial: option),
                              );
                              if (edited == null) return;
                              setState(() =>
                                  group.options[optionIndex] = edited);
                            },
                          ),
                          IconButton(
                            tooltip: 'Eliminar opción',
                            icon: const Icon(Icons.delete, color: AppColors.danger),
                            onPressed: () => setState(
                                () => group.options.removeAt(optionIndex)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar opción"),
                  onPressed: () async {
                    final ExtraOption? option = await showDialog<ExtraOption>(
                      context: context,
                      builder: (_) => const CreateExtraOptionDialog(),
                    );
                    if (option == null) return;
                    setState(() => group.options.add(option));
                  },
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Editar grupo"),
                      onPressed: () => _editGroup(groupIndex),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: AppColors.danger),
                      label: const Text("Eliminar grupo",
                          style: TextStyle(color: AppColors.danger)),
                      onPressed: () =>
                          setState(() => extraGroups.removeAt(groupIndex)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        SizedBox(
          width: 355,
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Agregar Grupo"),
            onPressed: () async {
              final ExtraGroup? group = await showDialog<ExtraGroup>(
                context: context,
                builder: (_) => const CreateExtraGroupDialog(),
              );
              if (group == null) return;
              setState(() => extraGroups.add(group));
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
      maxWidth: 1600, // suficiente para el menú y sube más rápido
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => images.add(_NewImage(bytes, image.name)));
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Un grupo sin opciones no tiene sentido (y la API lo rechaza si es obligatorio)
    final emptyGroup = extraGroups.where((g) => g.options.isEmpty);
    if (emptyGroup.isNotEmpty) {
      Get.snackbar('Falta completar',
          'El grupo "${emptyGroup.first.title}" no tiene opciones');
      return;
    }

    final companyId = AuthController.to.activeCompanyId.value;
    if (companyId == null) {
      Get.snackbar('Error', 'No hay restaurante seleccionado');
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Subir solo las fotos nuevas
      final uploaded = <String>[];
      for (final image in images) {
        uploaded.add(await storageService.uploadProductImage(
          image.bytes,
          companyId,
          filename: image.name,
        ));
      }

      // 2) Crear o actualizar
      final product = Product(
        id: widget.product?.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        basePrice: double.parse(priceController.text.trim()),
        categoryId: selectedCategory!,
        isAvailable: isAvailable,
        imageUrl: [...existingImages, ...uploaded],
        extras: extraGroups,
      );
      final ok = _isEdit
          ? await _productController.updateProduct(product)
          : await _productController.createProduct(product);

      if (ok && mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      Get.snackbar('No se pudieron subir las imágenes', e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
