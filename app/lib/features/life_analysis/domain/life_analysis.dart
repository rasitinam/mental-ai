/// Mirrors `mental_domain::report::LifeAnalysis` — the longer-horizon
/// (30-day) narrative produced by `mental-analysis-engine::generate_life_analysis`.
class LifeAnalysis {
  final DateTime periodStart;
  final DateTime periodEnd;
  final String narrative;
  final List<String> keyPatterns;
  final DateTime generatedAt;

  const LifeAnalysis({
    required this.periodStart,
    required this.periodEnd,
    required this.narrative,
    required this.keyPatterns,
    required this.generatedAt,
  });

  factory LifeAnalysis.fromJson(Map<String, dynamic> json) => LifeAnalysis(
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        narrative: json['narrative'] as String,
        keyPatterns: (json['key_patterns'] as List<dynamic>? ?? []).cast<String>(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );
}
