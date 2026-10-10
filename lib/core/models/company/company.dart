import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/location.dart';

class Company {
  final String id;
  final String name;
  final String slug;
  final String? taxId; // NIT
  final String phone;
  final String? whatsappPhone;
  final String? email;

  final LocationModel location;
  final List<BusinessHours> businessHours;

  final String logoUrl;
  final String? coverUrl;
  final String? primaryColor;
  final bool isActive;

  /// Calculado por la API al cargar el menú
  final bool isOpenNow;

  Company({
    required this.id,
    required this.name,
    this.slug = '',
    this.taxId,
    this.phone = '',
    this.whatsappPhone,
    this.email,
    required this.location,
    this.businessHours = const [],
    this.logoUrl = '',
    this.coverUrl,
    this.primaryColor,
    this.isActive = true,
    this.isOpenNow = true,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      taxId: json['taxId'],
      phone: json['phone'] ?? '',
      whatsappPhone: json['whatsappPhone'],
      email: json['email'],
      location: LocationModel(
        lat: (json['latitude'] as num?)?.toDouble(),
        lng: (json['longitude'] as num?)?.toDouble(),
        address: json['address'] ?? '',
      ),
      businessHours: ((json['businessHours'] as List?) ?? [])
          .map((h) => BusinessHours.fromJson(Map<String, dynamic>.from(h)))
          .toList()
        ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek)),
      logoUrl: json['logoUrl'] ?? '',
      coverUrl: json['coverUrl'],
      primaryColor: json['primaryColor'],
      isActive: json['isActive'] ?? true,
      isOpenNow: json['isOpenNow'] ?? true,
    );
  }

  /// Cuerpo para PATCH /companies/:companyId (datos del perfil)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (taxId != null) 'taxId': taxId,
      if (phone.isNotEmpty) 'phone': phone,
      if (whatsappPhone != null) 'whatsappPhone': whatsappPhone,
      if (email != null) 'email': email,
      if (location.address.isNotEmpty) 'address': location.address,
      if (location.lat != null) 'latitude': location.lat,
      if (location.lng != null) 'longitude': location.lng,
      if (logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (primaryColor != null) 'primaryColor': primaryColor,
    };
  }
}
