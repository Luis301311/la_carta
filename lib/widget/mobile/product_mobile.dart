import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/models/category.dart';

class ProductMobile extends StatelessWidget {
  final ProductCategory categoria ;
  const ProductMobile({super.key , required this.categoria});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// CATEGORIA
          Text(
            categoria.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          /// PRODUCTOS
          ...categoria.productos.map((producto) {
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
                        image: NetworkImage(producto.imagen),
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
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CustomColorBasic.black1,
                          ),
                        ),
                        Text(
                          producto.descripcion,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w300,
                            color: CustomColorBasic.grey1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${producto.precio.toStringAsFixed(0)}", style: TextStyle(color: CustomColorBasic.black2),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}