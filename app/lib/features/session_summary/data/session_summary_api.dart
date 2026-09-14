import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// The latest self-report screening, as far as the summary shows it: the
/// three headline instruments a clinician will ask about first.
class SessionScreening {
  final int daysAgo;
  final int phq9Score;
  final String depressionBand;
  final int gad7Score;
  final String anxietyBand;
  final int who5Score;
  final String wellbeingBand;

  const SessionScreening({
    required this.daysAgo,
    required this.phq9Score,
    required this.depressionBand,
    required this.gad7Score,
    required this.anxietyBand,
    required this.who5Score,
    required this.wellbeingBand,
  });

  factory SessionScreening.fromJson(Map<String, dynamic> json) => SessionScreening(
        daysAgo: json['days_ago'] as int? ?? 0,
        phq9Score: json['phq9_score'] as int? ?? 0,
        depressionBand: json['depression_band'] as String? ?? '',
        gad7Score: json['gad7_score'] as int? ?? 0,
        anxietyBand: json['anxiety_band'] as String? ?? '',
        who5Score: json['who5_score'] as int? ?? 0,
        wellbeingBand: json['wellbeing_band'] as String? ?? '',
      );
}

/// Mirrors `backend/apps/server/src/routes/session_summary.rs`.
class SessionSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int moodDays;
  final int journalEntries;
  final String overview;
  final String moodCourse;
  final List<String> themes;
  final List<String> hardMoments;
  final List<String> whatHelped;
  final List<String> questionsToBring;
  final SessionScreening? screening;

  const SessionSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.moodDays,
    required this.journalEntries,
    required this.overview,
    required this.moodCourse,
    required this.themes,
    required this.hardMoments,
    required this.whatHelped,
    required this.questionsToBring,
    this.screening,
  });

  static List<String> _list(dynamic raw) =>
      (raw as List<dynamic>? ?? const []).map((e) => e as String).toList();

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        moodDays: json['mood_days'] as int? ?? 0,
        journalEntries: json['journal_entries'] as int? ?? 0,
        overview: json['overview'] as String? ?? '',
        moodCourse: json['mood_course'] as String? ?? '',
        themes: _list(json['themes']),
        hardMoments: _list(json['hard_moments']),
        whatHelped: _list(json['what_helped']),
        questionsToBring: _list(json['questions_to_bring']),
        screening: json['screening'] == null
            ? null
            : SessionScreening.fromJson(json['screening'] as Map<String, dynamic>),
      );
}

/// The chosen period has no mood check-ins or journal entries at all
/// (HTTP 422) — a different message from "something went wrong".
class NotEnoughRecordsException implements Exception {
  const NotEnoughRecordsException();
}

final sessionSummaryApiProvider =
    Provider<SessionSummaryApi>((ref) => SessionSummaryApi(ref.watch(apiClientProvider)));

class SessionSummaryApi {
  final Dio _dio;
  SessionSummaryApi(this._dio);

  Future<SessionSummary> generate({required int days, String? note}) async {
    try {
      final response = await _dio.post('/session-summary', data: {
        'days': days,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return SessionSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw const NotEnoughRecordsException();
      rethrow;
    }
  }
}
