class BusinessHours {
  /// 1 = lunes ... 7 = domingo (igual que DateTime.weekday)
  final int dayOfWeek;
  final String openTime; // "08:00"
  final String closeTime; // "18:00"
  final bool closed;

  BusinessHours({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  static const _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get dayName =>
      dayOfWeek >= 1 && dayOfWeek <= 7 ? _days[dayOfWeek - 1] : '';

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      openTime: json['openTime'] ?? '00:00',
      closeTime: json['closeTime'] ?? '00:00',
      closed: json['closed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'openTime': openTime,
      'closeTime': closeTime,
      'closed': closed,
    };
  }
}
