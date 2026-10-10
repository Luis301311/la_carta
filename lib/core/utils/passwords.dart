import 'dart:math';

/// Contraseñas y slugs para el panel del super admin
class Passwords {
  // Sin caracteres que se confunden al dictarlos (0/O, 1/l/I)
  static const _chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate([int length = 10]) {
    final r = Random.secure();
    return List.generate(length, (_) => _chars[r.nextInt(_chars.length)]).join();
  }
}

class Slug {
  static final valid = RegExp(r'^[a-z0-9]+(?:[-_][a-z0-9]+)*$');

  /// "Pizzería Don Tito" -> "pizzeria_don_tito"
  static String fromName(String name) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    var s = name.toLowerCase().trim();
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'^_+|_+$'), '');
    return s.length > 80 ? s.substring(0, 80) : s;
  }
}
