/// Empresa en la lista del super admin (GET /companies)
class CompanySummary {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final String? whatsappPhone;
  final String? logoUrl;
  final DateTime? createdAt;
  final int categories;
  final int products;
  final int orders;

  CompanySummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.whatsappPhone,
    this.logoUrl,
    this.createdAt,
    this.categories = 0,
    this.products = 0,
    this.orders = 0,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map?) ?? const {};
    final logo = json['logoUrl'];
    return CompanySummary(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['isActive'] ?? true,
      whatsappPhone: json['whatsappPhone'],
      logoUrl: (logo is String && logo.isNotEmpty) ? logo : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      categories: (stats['categories'] as num?)?.toInt() ?? 0,
      products: (stats['products'] as num?)?.toInt() ?? 0,
      orders: (stats['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Administrador de una empresa (GET /companies/:id/admins)
class CompanyAdmin {
  final String id;
  final String email;
  final String fullName;
  final bool isActive;
  final DateTime? lastLoginAt;

  CompanyAdmin({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    this.lastLoginAt,
  });

  factory CompanyAdmin.fromJson(Map<String, dynamic> json) => CompanyAdmin(
        id: json['id'],
        email: json['email'] ?? '',
        fullName: json['fullName'] ?? '',
        isActive: json['isActive'] ?? true,
        lastLoginAt: json['lastLoginAt'] == null
            ? null
            : DateTime.tryParse(json['lastLoginAt']),
      );
}
