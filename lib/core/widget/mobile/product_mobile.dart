import 'package:flutter/material.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/features/menu/pages/select_product.dart';

class ProductMobile extends StatelessWidget {
  final List<Product> products;
  final String productsCategory;
  const ProductMobile(
      {super.key, required this.products, required this.productsCategory});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final w = Responsive.contentWidth(context);
      final compact = w < 360;
      // Tamaños según el ancho disponible (no el de la pantalla)
      final hPadding = compact ? 14.0 : 20.0;
      final imageSize = compact ? 70.0 : 90.0;
      final titleSize = compact ? 15.0 : 16.0;
      final descSize = compact ? 12.0 : 13.0;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CATEGORIA
            Text(
              productsCategory,
              style: TextStyle(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// PRODUCTOS
            ...products.map((producto) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: CustomColorBasic.white3,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    // Navigator de Flutter en vez de Get.to: GetX usa el mismo
                    // nombre de ruta para todos los productos y, si su registro
                    // de rutas se desincroniza, ignora la navegación sin avisar.
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: producto),
                      ));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 10 : 14),
                      // Alto mínimo en vez de alto fijo: si el nombre o la
                      // descripción son largos, la tarjeta crece en vez de desbordarse
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: imageSize),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Container(
                                height: imageSize,
                                width: imageSize,
                                color: CustomColorBasic.white4,
                                child: producto.mainImage == null
                                    ? const Icon(Icons.fastfood,
                                        color: Colors.grey)
                                    : Image.network(
                                        producto.mainImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.fastfood,
                                                color: Colors.grey),
                                      ),
                              ),
                            ),
                            SizedBox(width: compact ? 12 : 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    producto.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w600,
                                      color: CustomColorBasic.black1,
                                    ),
                                  ),
                                  if (producto.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      producto.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: descSize,
                                        fontWeight: FontWeight.w300,
                                        color: CustomColorBasic.grey1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "\$${producto.basePrice.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                                color: CustomColorBasic.black2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
