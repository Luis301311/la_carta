import 'package:lacarta/core/models/company/business_hours.dart';
import 'package:lacarta/core/models/company/location.dart';

class Company {
  final String id;
  final String name;
  final String taxId; // NIT
  final String phone;
  final String email;

  final LocationModel location;
  final List<BusinessHours> businessHours;

  final String logoUrl;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    required this.taxId,
    required this.phone,
    required this.email,
    required this.location,
    required this.businessHours,
    required this.logoUrl,
    required this.isActive,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      taxId: json['taxId'],
      phone: json['phone'],
      email: json['email'],
      location: LocationModel.fromJson(json['location']),
      businessHours: (json['businessHours'] as List)
          .map((h) => BusinessHours.fromJson(h))
          .toList(),
      logoUrl: json['logoUrl'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'taxId': taxId,
      'phone': phone,
      'email': email,
      'location': location.toJson(),
      'businessHours': businessHours.map((h) => h.toJson()).toList(),
      'logoUrl': logoUrl,
      'isActive': isActive,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    return Company(
      id: id,
      name: map['name'],
      taxId: map['taxId'],
      phone: map['phone'],
      email: map['email'],
      location: LocationModel.fromJson(map['location']),
       businessHours: map['businessHours'] != null
        ? (map['businessHours'] as List)
            .map((e) => BusinessHours.fromJson(e))
            .toList()
        : [],
      logoUrl: map['logoUrl'],
      isActive: map['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxId': taxId,
      'phone': phone,
      'email': email,
      'location': location.toJson(),
      'businessHours':
          businessHours.map((e) => e.toJson()).toList(),
      'logoUrl': logoUrl,
      'isActive': isActive,
    };
  }
}