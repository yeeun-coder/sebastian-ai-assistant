class Routine {
  final int id;
  final String category;
  final String title;
  final String targetTime;
  final String? repeatDays;
  final String? repeatInterval;
  final int? repeatDayOfMonth;
  final int? repeatMonth;
  final String? biweeklyAnchorDate;
  final bool isActive;

  Routine({
    required this.id,
    required this.category,
    required this.title,
    required this.targetTime,
    required this.repeatDays,
    required this.repeatInterval,
    required this.repeatDayOfMonth,
    required this.repeatMonth,
    required this.biweeklyAnchorDate,
    required this.isActive,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();

    final repeatDaysRaw = json['repeatDays'] ?? json['repeat_days'];
    final intervalRaw =
        json['repeatInterval'] ?? json['repeat_interval'] ?? '';
    final activeRaw = json['isActive'] ?? json['is_active'];
    final biweeklyRaw = s(json['biweeklyAnchorDate'] ?? json['biweekly_anchor_date']);

    return Routine(
      id: (json['id'] as num).toInt(),
      category: s(json['category']),
      title: s(json['title']),
      targetTime: s(json['targetTime'] ?? json['target_time']),
      repeatDays: s(repeatDaysRaw),
      repeatInterval: s(intervalRaw).isEmpty ? null : s(intervalRaw),
      repeatDayOfMonth: _intOrNull(json['repeatDayOfMonth'] ?? json['repeat_day_of_month']),
      repeatMonth: _intOrNull(json['repeatMonth'] ?? json['repeat_month']),
      biweeklyAnchorDate: biweeklyRaw.isEmpty ? null : biweeklyRaw,
      isActive: activeRaw == true || activeRaw == 1 || s(activeRaw).toLowerCase() == 'true',
    );
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Routine copyWith({
    bool? isActive,
  }) {
    return Routine(
      id: id,
      category: category,
      title: title,
      targetTime: targetTime,
      repeatDays: repeatDays,
      repeatInterval: repeatInterval,
      repeatDayOfMonth: repeatDayOfMonth,
      repeatMonth: repeatMonth,
      biweeklyAnchorDate: biweeklyAnchorDate,
      isActive: isActive ?? this.isActive,
    );
  }
}