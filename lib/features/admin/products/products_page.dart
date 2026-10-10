import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/category_controller.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/utils/format.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/features/admin/create_product_page.dart';

/// Panel: todos los productos del restaurante (también los agotados).
/// Buscar, filtrar por categoría, marcar agotado en un toque, editar y eliminar.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductController _products =
      Get.put(ProductController(admin: true), tag: 'admin');
  final CategoryController _categories =
      Get.put(CategoryController(admin: true), tag: 'admin');

  final _search = TextEditingController();
  String _query = '';

  /// null = todas
  String? _categoryId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm([Product? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProductPage(product: product)),
    );
    // La lista ya se actualizó en el controlador; se recarga por si acaso
    if (saved == true) _products.fetchProducts();
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${p.name}"?'),
        content: const Text(
            'Desaparece del menú. Los pedidos anteriores conservan su nombre y precio.\n\n'
            'Si solo se acabó por hoy, mejor márcalo como agotado.'),
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
    if (ok == true) _products.deleteProduct(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _products.fetchProducts();
              _categories.fetchCategories();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar producto…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Filtro por categoría
            SizedBox(
              height: 52,
              child: Obx(() {
                final cats = _categories.categories.toList();
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                    ),
                    ...cats.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: _categoryId == c.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = c.id),
                          ),
                        )),
                  ],
                );
              }),
            ),

            // Lista
            Expanded(
              child: Obx(() {
                final all = _products.products.toList();
                final catNames = {
                  for (final c in _categories.categories) c.id: c.name
                };
                if (_products.isLoading.value && all.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = all.where((p) {
                  if (_categoryId != null && p.categoryId != _categoryId) {
                    return false;
                  }
                  if (_query.isEmpty) return true;
                  return p.name.toLowerCase().contains(_query) ||
                      p.description.toLowerCase().contains(_query);
                }).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                if (list.isEmpty) {
                  return Center(
                    child: Text(all.isEmpty
                        ? 'Aún no hay productos. Crea el primero con "Nuevo producto".'
                        : 'Ningún producto coincide con la búsqueda'),
                  );
                }

                final agotados = all.where((p) => !p.isAvailable).length;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        '${all.length} productos'
                        '${agotados > 0 ? ' · $agotados agotados' : ''}',
                        style: const TextStyle(color: CustomColorBasic.grey1),
                      );
                    }
                    final p = list[i - 1];
                    return _ProductTile(
                      product: p,
                      categoryName: catNames[p.categoryId] ?? '',
                      onEdit: () => _openForm(p),
                      onDelete: () => _confirmDelete(p),
                      onToggle: (v) => _products.setAvailability(p, v),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ProductTile({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final available = product.isAvailable;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Foto (gris si está agotado)
              Opacity(
                opacity: available ? 1 : 0.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: CustomColorBasic.white4,
                    child: product.mainImage == null
                        ? const Icon(Icons.fastfood, color: Colors.grey)
                        : Image.network(
                            product.mainImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        decoration:
                            available ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${Fmt.money(product.basePrice)}'
                      '${categoryName.isNotEmpty ? ' · $categoryName' : ''}'
                      '${product.extras.isNotEmpty ? ' · ${product.extras.length} grupos de extras' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: CustomColorBasic.grey1),
                    ),
                  ],
                ),
              ),
              // Disponible / Agotado en un toque
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: available,
                    onChanged: onToggle,
                  ),
                  Text(
                    available ? 'Disponible' : 'Agotado',
                    style: TextStyle(
                      fontSize: 11,
                      color: available ? Colors.green.shade700 : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit), title: Text('Editar')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: AppColors.danger),
                      title: Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
