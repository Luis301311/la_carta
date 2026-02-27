import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/models/producto.dart';

class ProductMobile extends StatelessWidget {
  final List<Product> products ;
  final String productsCategory ;
  const ProductMobile({super.key , required this.products, required this.productsCategory});
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    double titleSize = (screenWidth * 0.04).clamp(14.0, 22.0);
    double descSize  = (screenWidth * 0.03).clamp(12.0, 18.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// CATEGORIA
          Text(
            productsCategory,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          /// PRODUCTOS
          ...products.map((producto) {
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: CustomColorBasic.white3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      image: DecorationImage(
                        image: NetworkImage(producto.imageUrl.toString()),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.name,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: CustomColorBasic.black1,
                          ),
                        ),
                        Text(
                          producto.description,
                          style: TextStyle(
                            fontSize: descSize,
                            fontWeight: FontWeight.w300,
                            color: CustomColorBasic.grey1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${producto.basePrice.toStringAsFixed(0)}", style: TextStyle(color: CustomColorBasic.black2),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}