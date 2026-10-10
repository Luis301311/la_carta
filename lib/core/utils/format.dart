/// Formatos sin dependencias extra (pesos colombianos y fechas cortas).
class Fmt {
  /// 12500 -> "$12.500"
  static String money(num value) {
    final digits = value.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}\$$buf';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Hora local "14:05"; si no es de hoy, "09/10 14:05"
  static String orderTime(DateTime date) {
    final d = date.toLocal();
    final now = DateTime.now();
    final time = '${_two(d.hour)}:${_two(d.minute)}';
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? time : '${_two(d.day)}/${_two(d.month)} $time';
  }

  /// "hace 5 min", "hace 2 h"
  static String ago(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}
