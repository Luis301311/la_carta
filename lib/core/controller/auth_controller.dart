import 'dart:convert';

import 'package:get/get.dart';
import 'package:lacarta/config/app_routes.dart';
import 'package:lacarta/config/session.dart';
import 'package:lacarta/core/models/auth_user.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesión del panel. Guarda el token en el dispositivo (en web, en el
/// almacenamiento del navegador) para no pedir login en cada recarga.
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kCompanyId = 'auth_company_id';
  static const _kCompanyName = 'auth_company_name';

  final AuthService _service = AuthService();

  final Rxn<AuthUser> user = Rxn<AuthUser>();

  /// Empresa que se está administrando. Para el admin de empresa es la suya;
  /// el super admin la escoge en la lista de empresas.
  final RxnString activeCompanyId = RxnString();
  final RxString activeCompanyName = ''.obs;

  final RxBool isLoading = false.obs;

  /// Mientras se restaura la sesión al abrir la app todavía no hay
  /// navegador, así que un 401 ahí solo limpia la sesión (no navega).
  bool _restoring = false;

  bool get isLoggedIn => user.value != null;
  bool get isSuperAdmin => user.value?.isSuperAdmin ?? false;

  @override
  void onInit() {
    super.onInit();
    // Si la API responde 401 con un token puesto, la sesión venció
    ApiClient.onUnauthorized = () {
      if (isLoggedIn && !_restoring) {
        logout(message: 'Tu sesión expiró. Inicia sesión de nuevo.');
      }
    };
  }

  /// Se llama en main.dart antes de arrancar la app
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final rawUser = prefs.getString(_kUser);
    if (token == null || rawUser == null) return;

    _restoring = true;
    try {
      Session.token = token;
      user.value = AuthUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawUser) as Map));
      _setActiveCompanyFromUser(
        savedId: prefs.getString(_kCompanyId),
        savedName: prefs.getString(_kCompanyName),
      );

      // Verifica que el token siga sirviendo (y refresca los datos del usuario)
      final fresh = await _service.me();
      user.value = fresh;
      await prefs.setString(_kUser, jsonEncode(fresh.toJson()));
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) await _clear();
      // Sin conexión: se queda con lo guardado
    } catch (_) {
      await _clear();
    } finally {
      _restoring = false;
    }
  }

  /// Devuelve null si todo salió bien, o el mensaje de error
  Future<String?> login(String email, String password) async {
    isLoading.value = true;
    try {
      Session.token = null;
      final result = await _service.login(email, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, result.token);
      await prefs.setString(_kUser, jsonEncode(result.user.toJson()));
      await prefs.remove(_kCompanyId);
      await prefs.remove(_kCompanyName);

      Session.token = result.token;
      user.value = result.user;
      _setActiveCompanyFromUser();

      goHome();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Inicio según el rol
  void goHome() {
    if (isSuperAdmin && activeCompanyId.value == null) {
      Get.offAllNamed(AppRoutes.companies);
    } else {
      Get.offAllNamed(AppRoutes.admin);
    }
  }

  /// Super admin: entrar al panel de una empresa
  Future<void> selectCompany(String id, String name) async {
    activeCompanyId.value = id;
    activeCompanyName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompanyId, id);
    await prefs.setString(_kCompanyName, name);
    Get.offAllNamed(AppRoutes.admin);
  }

  /// Super admin: volver a la lista de empresas
  Future<void> leaveCompany() async {
    activeCompanyId.value = null;
    activeCompanyName.value = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompanyId);
    await prefs.remove(_kCompanyName);
    Get.offAllNamed(AppRoutes.companies);
  }

  Future<void> logout({String? message}) async {
    await _clear();
    Get.offAllNamed(AppRoutes.login);
    if (message != null) {
      Get.snackbar('Sesión cerrada', message);
    }
  }

  Future<List<Map<String, dynamic>>> listCompanies() =>
      _service.listCompanies();

  void _setActiveCompanyFromUser({String? savedId, String? savedName}) {
    final u = user.value;
    if (u == null) return;
    if (u.isSuperAdmin) {
      activeCompanyId.value = savedId;
      activeCompanyName.value = savedName ?? '';
    } else {
      activeCompanyId.value = u.companyId;
      activeCompanyName.value = u.companyName ?? '';
    }
  }

  Future<void> _clear() async {
    Session.token = null;
    user.value = null;
    activeCompanyId.value = null;
    activeCompanyName.value = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    await prefs.remove(_kCompanyId);
    await prefs.remove(_kCompanyName);
  }
}
