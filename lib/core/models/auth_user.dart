class UserRole {
  static const superAdmin = 'SUPER_ADMIN';
  static const companyAdmin = 'COMPANY_ADMIN';
}

/// Usuario logueado (respuesta de /auth/login y /auth/me)
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? companyId;
  final String? companyName;
  final String? companySlug;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.companyId,
    this.companyName,
    this.companySlug,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map?;
    return AuthUser(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      companyId: json['companyId'],
      companyName: company?['name'],
      companySlug: company?['slug'],
    );
  }

  /// Mismo formato que la API, para guardarlo en el dispositivo
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'companyId': companyId,
        'company': companyId == null
            ? null
            : {'id': companyId, 'name': companyName, 'slug': companySlug},
      };
}
