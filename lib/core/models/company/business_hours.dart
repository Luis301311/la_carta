class BusinessHours {
  final String day;       // Monday, Tuesday...
  final String openTime;  // "08:00"
  final String closeTime; // "18:00"
  final bool  closed;

  BusinessHours({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      day: json['day'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      closed: json['closed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'openTime': openTime,
      'closeTime': closeTime,
      'closed': closed,
    };
  }
}