import 'package:lacarta/core/models/menu.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Menú público (sin login)
class MenuService {
  final ApiClient _api = ApiClient.instance;

  /// GET /public/:slug/menu — empresa, horario, categorías y productos con extras
  Future<RestaurantMenu> getMenu(String slug) async {
    final data = await _api.get('/public/${Uri.encodeComponent(slug)}/menu');
    return RestaurantMenu.fromJson(Map<String, dynamic>.from(data));
  }
}
