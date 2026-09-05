/// Mirrors `mental_domain::mood::MoodEntry` on the backend. `valence`
/// (unpleasant..pleasant) and `arousal` (calm..activated) follow the
/// circumplex model of affect, matching the Rust side exactly so the API
/// payload needs no translation.
class MoodEntry {
  final double valence;
  final double arousal;
  final List<String> tags;
  final String? note;
  final DateTime recordedAt;

  const MoodEntry({
    required this.valence,
    required this.arousal,
    this.tags = const [],
    this.note,
    required this.recordedAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        valence: (json['valence'] as num).toDouble(),
        arousal: (json['arousal'] as num).toDouble(),
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
        note: json['note'] as String?,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}
