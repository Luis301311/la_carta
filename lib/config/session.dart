/// Estado global mínimo de la app.
///
/// - [slug] y [companyId]: el restaurante que se está viendo (sale de la URL).
/// - [token]: JWT del admin. Mientras sea null, la app funciona como menú
///   público. El login del panel (siguiente paso) lo llenará.
class Session {
  static String slug = '';
  static String? companyId;
  static String? token;

  static bool get isLoggedIn => token != null;
}
