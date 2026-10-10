abstract class AppRoutes {
  static const splash = '/';

  static const menu = '/menu';

  static const login = '/login';

  /// Panel de la empresa (inicio)
  static const admin = '/admin';

  static const products = '/admin/products';

  static const orders = '/admin/orders';

  static const categories = '/admin/categories';

  static const users = '/admin/users';

  /// Métodos de pago del restaurante
  static const payments = '/admin/payments';

  /// Solo super admin: lista de empresas para escoger cuál administrar
  static const companies = '/admin/companies';
}
