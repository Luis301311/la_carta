import 'package:lacarta/core/models/product/producto.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Productos desde el panel de administración (requiere sesión)
class ProductServices {
  final ApiClient _api = ApiClient.instance;

  String _base(String companyId) => '/companies/$companyId/products';

  Future<List<Product>> getProducts(String companyId,
      {String? categoryId}) async {
    final data = await _api.get(
      _base(companyId),
      query: {'categoryId': categoryId},
    ) as List;
    return data
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Product> createProduct(String companyId, Product product) async {
    final data = await _api.post(_base(companyId), product.toJson());
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  /// Reemplaza todos los datos del producto, incluidos sus grupos de extras
  Future<Product> updateProduct(String companyId, Product product) async {
    final data =
        await _api.patch('${_base(companyId)}/${product.id}', product.toJson());
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> setAvailability(
          String companyId, String productId, bool isAvailable) =>
      _api.patch('${_base(companyId)}/$productId/availability',
          {'isAvailable': isAvailable});

  Future<void> deleteProduct(String companyId, String productId) =>
      _api.delete('${_base(companyId)}/$productId');
}
