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

  /// 48000 -> "$48k", 1250000 -> "$1,3M" (para ejes de gráficas)
  static String moneyShort(num value) {
    final v = value.abs();
    if (v >= 1000000) {
      final m = (v / 1000000);
      return '\$${m.toStringAsFixed(m >= 10 ? 0 : 1).replaceAll('.', ',')}M';
    }
    if (v >= 1000) return '\$${(v / 1000).round()}k';
    return '\$${v.round()}';
  }

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// "10 de oct. 2026"
  static String dateLong(DateTime d) =>
      '${d.day} de ${_months[d.month - 1]}. ${d.year}';

  /// "Lun", "Mar"...
  static String weekdayShort(DateTime d) => _days[d.weekday - 1];

  /// "6/10"
  static String dayMonth(DateTime d) => '${d.day}/${d.month}';

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
