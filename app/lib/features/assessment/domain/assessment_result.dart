/// Mirrors the backend's `AssessmentResponse` (`POST /assessment`,
/// `GET /assessment`) — the full seven-instrument screening battery:
/// PHQ-9, GAD-7, WHO-5, PHQ-15, PC-PTSD-5, AUDIT-C and CAGE-AID.
class AssessmentResult {
  final int phq9Score;
  final String depressionBand;
  final int gad7Score;
  final String anxietyBand;
  final int who5Score;
  final String wellbeingBand;
  final int phq15Score;
  final String somaticBand;
  final int ptsd5Score;
  final String ptsdBand;
  final int auditcScore;
  final String alcoholBand;
  final int cageaidScore;
  final String substanceBand;
  final bool crisisFlag;
  final DateTime createdAt;

  const AssessmentResult({
    required this.phq9Score,
    required this.depressionBand,
    required this.gad7Score,
    required this.anxietyBand,
    required this.who5Score,
    required this.wellbeingBand,
    required this.phq15Score,
    required this.somaticBand,
    required this.ptsd5Score,
    required this.ptsdBand,
    required this.auditcScore,
    required this.alcoholBand,
    required this.cageaidScore,
    required this.substanceBand,
    required this.crisisFlag,
    required this.createdAt,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) => AssessmentResult(
        phq9Score: json['phq9_score'] as int,
        depressionBand: json['depression_band'] as String,
        gad7Score: json['gad7_score'] as int,
        anxietyBand: json['anxiety_band'] as String,
        who5Score: json['who5_score'] as int,
        wellbeingBand: json['wellbeing_band'] as String,
        phq15Score: json['phq15_score'] as int,
        somaticBand: json['somatic_band'] as String,
        ptsd5Score: json['ptsd5_score'] as int,
        ptsdBand: json['ptsd_band'] as String,
        auditcScore: json['auditc_score'] as int,
        alcoholBand: json['alcohol_band'] as String,
        cageaidScore: json['cageaid_score'] as int,
        substanceBand: json['substance_band'] as String,
        crisisFlag: json['crisis_flag'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
