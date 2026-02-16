

import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/constant/list_producto.dart';
import 'package:lacarta/widget/mobile/header_mobile.dart';
import 'package:lacarta/widget/mobile/product_mobile.dart';
import 'package:lacarta/widget/mobile/seach_mobile.dart';
class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  
  final ScrollController _scrollController = ScrollController();
  int selectedCategory = 0;
  final Map<int, double> _categoryOffsets = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    double offset = _scrollController.offset;

    for (int i = 0; i < categorias.length; i++) {
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
    body: CustomScrollView(
    controller: _scrollController,
    slivers: [
          SliverToBoxAdapter(child: HeaderMobile()),
          SliverPersistentHeader(
            pinned:  true, 
            delegate: _CategoryHeaderDelegate(child: SeachMobile())),

          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
              child: _buildCategory(),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {

                return LayoutBuilder(
                  builder: (context, constraints) {

                    // posición real
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final position = box.localToGlobal(Offset.zero).dy;
                        _categoryOffsets[index] = _scrollController.offset + position;
                      }
                    });

                    final categoria = categorias[index];
                    return ProductMobile(categoria: categoria);
                  },
                );
              },
              childCount: categorias.length,
            ),
          ),
        ],
      ),
    );
  }


 Widget _buildCategory() {
  return Container(
    color: CustomColorBasic.white2,
    child: ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: categorias.length,
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
                categorias[index].nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? CustomColorBasic.yellow
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
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
