import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/models/product/producto.dart';

/// Respuesta de GET /public/:slug/menu
class RestaurantMenu {
  final Company company;
  final List<ProductCategory> categories;
  final List<Product> products;

  RestaurantMenu({
    required this.company,
    required this.categories,
    required this.products,
  });

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) {
    final categories = <ProductCategory>[];
    final products = <Product>[];

    for (final raw in (json['categories'] as List? ?? [])) {
      final c = Map<String, dynamic>.from(raw);
      categories.add(ProductCategory.fromJson(c));
      for (final p in (c['products'] as List? ?? [])) {
        products.add(Product.fromJson(Map<String, dynamic>.from(p)));
      }
    }

    return RestaurantMenu(
      company: Company.fromJson(Map<String, dynamic>.from(json['company'])),
      categories: categories,
      products: products,
    );
  }
}
