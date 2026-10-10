import 'dart:typed_data';

import 'package:lacarta/core/services/api_client.dart';

/// Sube imágenes a la API: POST /companies/:companyId/uploads/image
/// (la API las guarda en una carpeta por empresa y devuelve la URL pública)
class StorageService {
  final ApiClient _api = ApiClient.instance;

  Future<String> uploadProductImage(
    Uint8List bytes,
    String companyId, {
    String filename = 'producto.jpg',
  }) async {
    final data = await _api.uploadImage(
      '/companies/$companyId/uploads/image',
      bytes,
      filename: filename,
    );
    return (data as Map)['url'] as String;
  }
}
