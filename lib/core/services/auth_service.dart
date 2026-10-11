import 'package:lacarta/core/models/auth_user.dart';
import 'package:lacarta/core/services/api_client.dart';

class LoginResult {
  final String token;
  final AuthUser user;
  LoginResult(this.token, this.user);
}

class AuthService {
  final ApiClient _api = ApiClient.instance;

  Future<LoginResult> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map;
    return LoginResult(
      data['accessToken'] as String,
      AuthUser.fromJson(Map<String, dynamic>.from(data['user'])),
    );
  }

  Future<AuthUser> me() async {
    final data = await _api.get('/auth/me');
    return AuthUser.fromJson(Map<String, dynamic>.from(data));
  }

  /// PATCH /auth/password
  Future<void> changePassword(String current, String next) async {
    await _api.patch('/auth/password', {
      'currentPassword': current,
      'newPassword': next,
    });
  }

  /// Solo super admin: GET /companies (con conteos)
  Future<List<Map<String, dynamic>>> listCompanies() async {
    final data = await _api.get('/companies') as List;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
