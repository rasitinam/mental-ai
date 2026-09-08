/// Mirrors `mental_domain::UserState` — the home screen's "where are you
/// right now" reading, assessed from chat, the latest report, the latest
/// life analysis, journal entries and mood check-ins together.
class UserState {
  /// Unpleasant..pleasant, -1.0..1.0.
  final double valence;

  /// Drained..energized, -1.0..1.0.
  final double energy;
  final String headline;
  final String note;

  /// Which sources fed this reading, so the screen can show its work.
  final List<String> basis;
  final DateTime generatedAt;

  const UserState({
    required this.valence,
    required this.energy,
    required this.headline,
    required this.note,
    required this.basis,
    required this.generatedAt,
  });

  /// -1.0..1.0 mapped onto 1..5 stars, which is what the home screen shows
  /// instead of the raw decimals people can't read anything out of.
  static int stars(double value) {
    final normalized = (value.clamp(-1.0, 1.0) + 1) / 2;
    return (normalized * 4).round() + 1;
  }

  factory UserState.fromJson(Map<String, dynamic> json) => UserState(
        valence: (json['valence'] as num).toDouble(),
        energy: (json['energy'] as num).toDouble(),
        headline: json['headline'] as String,
        note: json['note'] as String,
        basis: (json['basis'] as List<dynamic>? ?? []).cast<String>(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );
}
