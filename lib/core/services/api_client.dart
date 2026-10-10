import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lacarta/config/api_config.dart';
import 'package:lacarta/config/session.dart';

/// Error devuelto por la API, con el mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP único para toda la app.
/// Agrega el token (si hay sesión) y convierte los errores de NestJS en
/// [ApiException] con un mensaje legible.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();

  /// Lo configura AuthController: qué hacer si la API responde 401
  /// estando logueado (token vencido o usuario desactivado).
  static void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final params = query == null
        ? null
        : {
            for (final e in query.entries)
              if (e.value != null) e.key: e.value.toString(),
          };
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: (params?.isEmpty ?? true) ? null : params);
  }

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _http
      .post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) => _send(() => _http
      .patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) => _send(() =>
      _http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers()));

  /// Sube una imagen (multipart, campo "file"). Devuelve el JSON de la API.
  Future<dynamic> uploadImage(
    String path,
    Uint8List bytes, {
    String filename = 'imagen.jpg',
    Map<String, String>? fields,
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields ?? const {})
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          // La API solo acepta imágenes: hay que decir el tipo explícitamente
          contentType: _imageType(filename),
        ));
      return http.Response.fromStream(await request.send());
    });
  }

  MediaType _imageType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call();
    } catch (_) {
      throw ApiException(
        0,
        'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). '
        '¿Está corriendo la API?',
      );
    }

    final text = utf8.decode(res.bodyBytes);
    final dynamic data = text.isEmpty ? null : _tryDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401 && Session.token != null) {
      onUnauthorized?.call();
    }
    throw ApiException(res.statusCode, _errorMessage(res.statusCode, data));
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  /// NestJS responde { message: "texto" } o { message: ["error 1", "error 2"] }
  String _errorMessage(int status, dynamic data) {
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is List) return m.join('\n');
      return m.toString();
    }
    switch (status) {
      case 401:
        return 'Debes iniciar sesión';
      case 403:
        return 'No tienes permisos para esta acción';
      case 404:
        return 'No encontrado';
      default:
        return 'Error del servidor ($status)';
    }
  }
}
