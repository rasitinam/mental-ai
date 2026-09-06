import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/life_analysis.dart';

final lifeAnalysisApiProvider = Provider<LifeAnalysisApi>((ref) => LifeAnalysisApi(ref.watch(apiClientProvider)));

class LifeAnalysisApi {
  final Dio _dio;
  LifeAnalysisApi(this._dio);

  Future<LifeAnalysis?> latest() async {
    final response = await _dio.get('/life-analysis/latest');
    if (response.data == null) return null;
    return LifeAnalysis.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LifeAnalysis> generate() async {
    final response = await _dio.post('/life-analysis/generate');
    return LifeAnalysis.fromJson(response.data as Map<String, dynamic>);
  }
}
