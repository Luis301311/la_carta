

import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/menu_brand.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/category_controller.dart';
import 'package:lacarta/core/controller/product_controller.dart';
import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/widget/mobile/header_mobile.dart';
import 'package:lacarta/core/widget/mobile/product_mobile.dart';
import 'package:lacarta/core/widget/mobile/seach_mobile.dart';
class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  final ProductController productController = Get.put(ProductController());
  final CategoryController categoryController = Get.put(CategoryController());
  final ScrollController _scrollController = ScrollController();
  int selectedCategory = 0;

  /// Texto del buscador
  String _query = '';

  /// Productos de una categoría que coinciden con la búsqueda
  List<Product> _productsFor(ProductCategory c) {
    final q = _query.trim().toLowerCase();
    return productController.products
        .where((p) =>
            p.categoryId == c.id &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q)))
        .toList();
  }

  /// Categorías con al menos un producto que coincide
  List<ProductCategory> get _visibleCategories => categoryController
      .categories
      .where((c) => _productsFor(c).isNotEmpty)
      .toList();

  void _onSearch(String value) {
    setState(() {
      _query = value;
      selectedCategory = 0;
      _categoryOffsets.clear(); // las posiciones cambian al filtrar
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }
  final Map<int, double> _categoryOffsets = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    double offset = _scrollController.offset;

    final count = _visibleCategories.length;
    for (int i = 0; i < count; i++) {
      double? start = _categoryOffsets[i];
      double? nextStart = _categoryOffsets[i + 1];

      if (start != null &&
          offset >= start &&
          (nextStart == null || offset < nextStart)) {

        if (selectedCategory != i) {
          setState(() {
            selectedCategory = i;
          });
        }
        break;
      }
    }
  }

  void _scrollToCategory(int index) {
    final offset = _categoryOffsets[index];

    if (offset != null) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: CustomColorBasic.white2,
    // En PC/tablet el menú queda centrado con un ancho máximo
    body: ResponsiveCenter(
    child: CustomScrollView(
    controller: _scrollController,
    slivers: [
          SliverToBoxAdapter(child: HeaderMobile()),
          SliverPersistentHeader(
            pinned:  true, 
            delegate: _CategoryHeaderDelegate(
                child: SeachMobile(onChanged: _onSearch))),

          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
              child: _buildCategory(),
            ),
          ),
          
          Obx( (){
              final cats = _visibleCategories;
              if (cats.isEmpty && _query.trim().isNotEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No encontramos "${_query.trim()}" en el menú',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = cats[index];
                    final productsForCategory = _productsFor(category);
                    // Builder (no LayoutBuilder): solo se necesita el context
                    // para medir la posición de la categoría
                    return Builder(
                      builder: (context) {
                        // posición real
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final box = context.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final position = box.localToGlobal(Offset.zero).dy;
                            _categoryOffsets[index] = _scrollController.offset + position;
                          }
                        });
                        //vistas productos
                        
                        return ProductMobile(products: productsForCategory, productsCategory: category.name,);
                      },
                    );
                  },
                  childCount: cats.length,
                ),
              );
            }
          ),
        ],
      ),
    ),
    );
  }


 Widget _buildCategory() {
  final cats = _visibleCategories;
  return Container(
    color: CustomColorBasic.white2,
    child: ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: cats.length,
      itemBuilder: (context, index) {

        final bool isSelected = selectedCategory == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCategory = index;
            });
            _scrollToCategory(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 22,),
            decoration: BoxDecoration(
              color: isSelected
                  ? CustomColorBasic.white2
                  : CustomColorBasic.white2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                  ? CustomColorBasic.white2
                  : CustomColorBasic.white2, 
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                cats[index].name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? MenuBrand.color
                      : CustomColorBasic.grey1,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


 
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context, double shrinkOffset, bool overlapsContent) {
    // El hijo SIEMPRE debe ocupar todo el alto del encabezado (60 px).
    // Si mide menos, Flutter lanza "layoutExtent exceeds paintExtent" y la
    // pantalla deja de responder a los toques.
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
