import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/company.dart';
import 'package:lacarta/core/services/api_client.dart';

/// Datos de la empresa desde el panel (requiere sesión)
class CompanyService {
  final ApiClient _api = ApiClient.instance;

  Future<Company> getCompany(String companyId) async {
    final data = await _api.get('/companies/$companyId');
    return Company.fromJson(Map<String, dynamic>.from(data));
  }

  /// PATCH parcial: solo los campos que se envían (p. ej. los de pagos)
  Future<Company> patchCompany(
      String companyId, Map<String, dynamic> fields) async {
    final data = await _api.patch('/companies/$companyId', fields);
    return Company.fromJson(Map<String, dynamic>.from(data));
  }

  /// PUT /companies/:id/hours — reemplaza el horario completo
  Future<List<BusinessHours>> setHours(
      String companyId, List<BusinessHours> hours) async {
    final data = await _api.put('/companies/$companyId/hours', {
      'hours': hours.map((h) => h.toJson()).toList(),
    }) as List;
    return data
        .map((e) => BusinessHours.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Company> updateCompany(Company company) async {
    final data = await _api.patch('/companies/${company.id}', company.toJson());
    return Company.fromJson(Map<String, dynamic>.from(data));
  }
}
