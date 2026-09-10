/// Mirrors the backend's `AssessmentResponse` (`POST /assessment`,
/// `GET /assessment`) — a PHQ-9 + GAD-7 screening reading.
class AssessmentResult {
  final int phq9Score;
  final String depressionBand;
  final int gad7Score;
  final String anxietyBand;
  final bool crisisFlag;
  final DateTime createdAt;

  const AssessmentResult({
    required this.phq9Score,
    required this.depressionBand,
    required this.gad7Score,
    required this.anxietyBand,
    required this.crisisFlag,
    required this.createdAt,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) => AssessmentResult(
        phq9Score: json['phq9_score'] as int,
        depressionBand: json['depression_band'] as String,
        gad7Score: json['gad7_score'] as int,
        anxietyBand: json['anxiety_band'] as String,
        crisisFlag: json['crisis_flag'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
