import 'package:lacarta/models/producto.dart';

class ProductCategory {
  final String nombre;
  final List<Producto> productos;

  ProductCategory({
    required this.nombre,
    required this.productos,
  });
}