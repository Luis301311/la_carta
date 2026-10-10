import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/category_controller.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/widget/responsive.dart';

/// Panel: categorías del menú. Crear, renombrar, ordenar arrastrando,
/// activar/desactivar y eliminar.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryController _c =
      Get.put(CategoryController(admin: true), tag: 'admin');
  // Para mostrar cuántos productos tiene cada categoría
  final ProductController _products =
      Get.put(ProductController(admin: true), tag: 'admin');

  /// Diálogo para crear (category == null) o editar
  Future<void> _openDialog([ProductCategory? category]) async {
    final result = await showDialog<({String name, String description})>(
      context: context,
      builder: (_) => _CategoryDialog(initial: category),
    );
    if (result == null) return;

    if (category == null) {
      await _c.createCategory(ProductCategory(
        name: result.name,
        description: result.description.isEmpty ? null : result.description,
        // Al final de la lista
        sortOrder: _c.categories.length,
      ));
    } else {
      await _c.updateCategory(category.copyWith(
        name: result.name,
        description: result.description,
      ));
    }
  }

  Future<void> _confirmDelete(ProductCategory category, int productCount) async {
    if (productCount > 0) {
      // La API tampoco lo permite; se explica antes de intentarlo
      Get.snackbar(
        'No se puede eliminar',
        '"${category.name}" tiene $productCount producto(s). Muévelos a otra '
            'categoría o elimínalos primero. Si solo quieres ocultarla, desactívala.',
        duration: const Duration(seconds: 6),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${category.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) _c.deleteCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Categorías'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _c.fetchCategories();
              _products.fetchProducts();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: Obx(() {
          final cats = _c.categories.toList();
          final counts = <String, int>{};
          for (final p in _products.products) {
            counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
          }

          if (_c.isLoading.value && cats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no hay categorías.\nCrea la primera, por ejemplo "Hamburguesas" o "Bebidas".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Arrastra ☰ para cambiar el orden en que salen en el menú. '
                  'Las inactivas no se muestran a los clientes.',
                  style: TextStyle(color: CustomColorBasic.grey1),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                  buildDefaultDragHandles: false,
                  itemCount: cats.length,
                  onReorder: _c.reorder,
                  itemBuilder: (context, i) {
                    final cat = cats[i];
                    final n = counts[cat.id] ?? 0;
                    return Card(
                      key: ValueKey(cat.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cat.isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          '$n producto${n == 1 ? '' : 's'}'
                          '${cat.isActive ? '' : ' · Inactiva (oculta en el menú)'}',
                        ),
                        onTap: () => _openDialog(cat),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: cat.isActive
                                  ? 'Visible en el menú'
                                  : 'Oculta en el menú',
                              child: Switch(
                                value: cat.isActive,
                                onChanged: (v) => _c.updateCategory(
                                    cat.copyWith(isActive: v),
                                    showMessage: false),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Más opciones',
                              onSelected: (v) {
                                if (v == 'edit') _openDialog(cat);
                                if (v == 'delete') _confirmDelete(cat, n);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Renombrar')),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.delete, color: AppColors.danger),
                                    title: Text('Eliminar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final ProductCategory? initial;
  const _CategoryDialog({this.initial});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _description =
      TextEditingController(text: widget.initial?.description ?? '');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context,
        (name: _name.text.trim(), description: _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nueva categoría' : 'Editar categoría'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej.: Hamburguesas',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Escribe un nombre';
                if (t.length > 100) return 'Máximo 100 caracteres';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
