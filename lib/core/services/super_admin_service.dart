import 'package:lacarta/core/models/company_summary.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Llamadas exclusivas del super admin (la API devuelve 403 a cualquier otro rol)
class SuperAdminService {
  final ApiClient _api = ApiClient.instance;

  Future<List<CompanySummary>> listCompanies({String? search}) async {
    final data = await _api.get('/companies', query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    }) as List;
    return data
        .map((e) => CompanySummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Crea la empresa y (opcional) su primer administrador en una sola operación
  Future<void> createCompany({
    required String name,
    required String slug,
    String? whatsappPhone,
    String? adminName,
    String? adminEmail,
    String? adminPassword,
  }) async {
    await _api.post('/companies', {
      'name': name,
      'slug': slug,
      if (whatsappPhone != null) 'whatsappPhone': whatsappPhone,
      if (adminEmail != null)
        'admin': {
          'fullName': adminName,
          'email': adminEmail,
          'password': adminPassword,
        },
    });
  }

  Future<void> updateCompany(String id,
      {required String name, required String slug, String? whatsappPhone}) {
    return _api.patch('/companies/$id', {
      'name': name,
      'slug': slug,
      'whatsappPhone': whatsappPhone,
    });
  }

  Future<void> setActive(String id, bool isActive) =>
      _api.patch('/companies/$id/status', {'isActive': isActive});

  Future<void> deleteCompany(String id) => _api.delete('/companies/$id');

  // ---------- Administradores de cada empresa ----------

  Future<List<CompanyAdmin>> listAdmins(String companyId) async {
    final data = await _api.get('/companies/$companyId/admins') as List;
    return data
        .map((e) => CompanyAdmin.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createAdmin(String companyId,
      {required String fullName,
      required String email,
      required String password}) {
    return _api.post('/companies/$companyId/admins', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<void> setAdminActive(String companyId, String userId, bool isActive) =>
      _api.patch('/companies/$companyId/admins/$userId/status',
          {'isActive': isActive});

  Future<void> resetAdminPassword(
          String companyId, String userId, String password) =>
      _api.patch('/companies/$companyId/admins/$userId/password',
          {'password': password});
}
