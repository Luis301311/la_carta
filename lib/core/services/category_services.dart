import 'package:lacarta/core/models/category.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Categorías desde el panel de administración (requiere sesión)
class CategoryServices {
  final ApiClient _api = ApiClient.instance;

  String _base(String companyId) => '/companies/$companyId/categories';

  Future<List<ProductCategory>> getCategories(String companyId) async {
    final data = await _api.get(_base(companyId)) as List;
    return data
        .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProductCategory> createCategory(
      String companyId, ProductCategory category) async {
    final data = await _api.post(_base(companyId), category.toJson());
    return ProductCategory.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ProductCategory> updateCategory(
      String companyId, ProductCategory category) async {
    final data =
        await _api.patch('${_base(companyId)}/${category.id}', category.toJson());
    return ProductCategory.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteCategory(String companyId, String id) =>
      _api.delete('${_base(companyId)}/$id');
}
