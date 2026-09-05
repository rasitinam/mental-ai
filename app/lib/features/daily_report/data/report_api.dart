import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/daily_report.dart';

final reportApiProvider = Provider<ReportApi>((ref) => ReportApi(ref.watch(apiClientProvider)));

class ReportApi {
  final Dio _dio;
  ReportApi(this._dio);

  Future<DailyReport?> latest() async {
    final response = await _dio.get('/reports/latest');
    if (response.data == null) return null;
    return DailyReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DailyReport> generate() async {
    final response = await _dio.post('/reports/generate');
    return DailyReport.fromJson(response.data as Map<String, dynamic>);
  }
}
