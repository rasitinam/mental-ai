/// Mirrors the backend's `StreakSummary`. A day counts as active when it
/// holds at least one mood check-in, journal entry or chat message.
class StreakSummary {
  final int current;

  /// Activity counts for the last seven days, oldest first — the shape
  /// the home sparkline draws.
  final List<int> lastSeven;
  final int periodActive;
  final int periodDays;

  const StreakSummary({
    required this.current,
    required this.lastSeven,
    required this.periodActive,
    required this.periodDays,
  });

  static const empty = StreakSummary(
    current: 0,
    lastSeven: [0, 0, 0, 0, 0, 0, 0],
    periodActive: 0,
    periodDays: 14,
  );

  factory StreakSummary.fromJson(Map<String, dynamic> json) => StreakSummary(
        current: json['current'] as int? ?? 0,
        lastSeven: (json['last_seven'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
        periodActive: json['period_active'] as int? ?? 0,
        periodDays: json['period_days'] as int? ?? 14,
      );

  /// The busiest of the last seven days, floored at 1 so a week with a
  /// single entry doesn't divide by zero when the sparkline scales.
  int get peak => lastSeven.fold<int>(1, (max, day) => day > max ? day : max);
}
