import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/mood_entry.dart';

final moodApiProvider = Provider<MoodApi>((ref) => MoodApi(ref.watch(apiClientProvider)));

/// Thrown when the backend rejects a check-in because the once-per-day
/// cooldown hasn't elapsed yet (HTTP 429) — see
/// `apps/server/src/routes/mood.rs`. Carries when the next one is
/// allowed so the UI can show a countdown instead of a generic error.
class MoodCooldownException implements Exception {
  final DateTime retryAfter;
  const MoodCooldownException(this.retryAfter);
}

class MoodApi {
  final Dio _dio;
  MoodApi(this._dio);

  Future<void> addMood({
    required double valence,
    required double arousal,
    List<String> tags = const [],
    String? note,
  }) async {
    try {
      await _dio.post('/mood', data: {
        'valence': valence,
        'arousal': arousal,
        'tags': tags,
        'note': ?note,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfterRaw = e.response?.data?['retry_after'] as String?;
        if (retryAfterRaw != null) {
          throw MoodCooldownException(DateTime.parse(retryAfterRaw));
        }
      }
      rethrow;
    }
  }

  Future<MoodEntry?> latest() async {
    final response = await _dio.get('/mood/latest');
    if (response.data == null) return null;
    return MoodEntry.fromJson(response.data as Map<String, dynamic>);
  }
}

/// The most recent check-in, for screens that only need a quick read of
/// "how are they doing right now" (the home screen's mood face) rather
/// than the full cooldown-aware submit flow in [moodControllerProvider].
final latestMoodProvider = FutureProvider<MoodEntry?>((ref) async {
  return ref.watch(moodApiProvider).latest();
});
