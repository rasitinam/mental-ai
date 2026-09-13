/// The last seven days, boiled down to what the recap card actually shows.
/// Computed client-side from data the app already fetches (mood history,
/// the journal archive, the streak summary) — no new backend endpoint
/// carries a pre-aggregated version of this, since it's cheap enough to
/// fold over locally and never needs to be shared across devices.
class RecapData {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int checkins;
  final int journalEntries;
  final int streak;

  /// Days within the period with at least one mood check-in or journal
  /// entry, out of 7.
  final int activeDays;

  /// Average valence across the period's check-ins, `null` when there
  /// were none to average.
  final double? avgValence;

  const RecapData({
    required this.periodStart,
    required this.periodEnd,
    required this.checkins,
    required this.journalEntries,
    required this.streak,
    required this.activeDays,
    required this.avgValence,
  });
}
