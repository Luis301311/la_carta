/// Estado global mínimo de la app.
///
/// - [slug] y [companyId]: el restaurante del menú público (sale de la URL).
/// - [token]: JWT del usuario logueado. Lo maneja AuthController; ApiClient
///   lo envía en cada petición.
class Session {
  static String slug = '';
  static String? companyId;
  static String? token;
}
