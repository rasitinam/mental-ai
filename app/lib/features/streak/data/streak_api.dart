import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_prefs.dart';
import '../domain/streak_summary.dart';

final streakApiProvider = Provider<StreakApi>((ref) => StreakApi(ref.watch(apiClientProvider)));

class StreakApi {
  final Dio _dio;
  StreakApi(this._dio);

  Future<StreakSummary> summary() async {
    final response = await _dio.get('/streak');
    return StreakSummary.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Read on the home, journal and life-analysis screens. Watches the
/// session so signing into another account doesn't show the previous
/// one's run, and falls back to an empty streak rather than an error
/// state: a missing counter should never be what stops those screens
/// from rendering.
final streakProvider = FutureProvider<StreakSummary>((ref) async {
  ref.watch(sessionTokenProvider);
  try {
    return await ref.watch(streakApiProvider).summary();
  } catch (_) {
    return StreakSummary.empty;
  }
});
