/// Configuración de la API.
///
/// Por defecto apunta a la API local. Para otro servidor:
///   flutter run -d chrome --dart-define=API_URL=https://api.midominio.com
///
/// En el emulador de Android "localhost" es el propio emulador; usa:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Restaurante que se abre cuando la URL no trae slug (p. ej. en desarrollo).
  static const String defaultSlug = String.fromEnvironment(
    'DEFAULT_SLUG',
    defaultValue: 'burger_house',
  );
}
