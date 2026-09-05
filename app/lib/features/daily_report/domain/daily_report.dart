/// Mirrors `mental_domain::report::DailyMentalReport`.
class DailyReport {
  final String summary;
  final String moodTrendNote;
  final List<String> recommendations;
  final bool crisisFlag;
  final DateTime generatedAt;

  const DailyReport({
    required this.summary,
    required this.moodTrendNote,
    required this.recommendations,
    required this.crisisFlag,
    required this.generatedAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
        summary: json['summary'] as String,
        moodTrendNote: json['mood_trend_note'] as String,
        recommendations: (json['recommendations'] as List<dynamic>? ?? []).cast<String>(),
        crisisFlag: json['crisis_flag'] as bool? ?? false,
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );
}
