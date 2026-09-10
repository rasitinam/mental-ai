import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/assessment_result.dart';

final assessmentApiProvider = Provider<AssessmentApi>((ref) => AssessmentApi(ref.watch(apiClientProvider)));

/// The signed-in user's most recent PHQ-9 + GAD-7 reading, if any — read
/// by the Settings screen so it can show when the person last took it
/// without every caller managing its own fetch.
final latestAssessmentProvider = FutureProvider<AssessmentResult?>(
  (ref) => ref.watch(assessmentApiProvider).latest(),
);

class AssessmentApi {
  final Dio _dio;
  AssessmentApi(this._dio);

  Future<AssessmentResult> submit({
    required List<int> phq9Answers,
    required List<int> gad7Answers,
  }) async {
    final response = await _dio.post('/assessment', data: {
      'phq9_answers': phq9Answers,
      'gad7_answers': gad7Answers,
    });
    return AssessmentResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssessmentResult?> latest() async {
    final response = await _dio.get('/assessment');
    final data = response.data;
    if (data == null) return null;
    return AssessmentResult.fromJson(data as Map<String, dynamic>);
  }
}
