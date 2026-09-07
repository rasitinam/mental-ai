import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/life_analysis.dart';

final lifeAnalysisApiProvider = Provider<LifeAnalysisApi>((ref) => LifeAnalysisApi(ref.watch(apiClientProvider)));

/// Thrown when the backend rejects generation because the once-a-week
/// cooldown hasn't elapsed (HTTP 429) — see
/// `apps/server/src/routes/life_analysis.rs`.
class LifeAnalysisCooldownException implements Exception {
  final DateTime retryAfter;
  const LifeAnalysisCooldownException(this.retryAfter);
}

class LifeAnalysisApi {
  final Dio _dio;
  LifeAnalysisApi(this._dio);

  Future<LifeAnalysis?> latest() async {
    final response = await _dio.get('/life-analysis/latest');
    if (response.data == null) return null;
    return LifeAnalysis.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LifeAnalysis> generate() async {
    try {
      final response = await _dio.post('/life-analysis/generate');
      return LifeAnalysis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfterRaw = e.response?.data?['retry_after'] as String?;
        if (retryAfterRaw != null) {
          throw LifeAnalysisCooldownException(DateTime.parse(retryAfterRaw));
        }
      }
      rethrow;
    }
  }
}
