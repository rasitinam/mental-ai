import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/journal_entry.dart';

final journalApiProvider = Provider<JournalApi>((ref) => JournalApi(ref.watch(apiClientProvider)));

/// Thrown when the backend rejects an entry because the once-per-day
/// cooldown hasn't elapsed (HTTP 429) — see
/// `apps/server/src/routes/journal.rs`. Mirrors `MoodCooldownException`.
class JournalCooldownException implements Exception {
  final DateTime retryAfter;
  const JournalCooldownException(this.retryAfter);
}

class JournalApi {
  final Dio _dio;
  JournalApi(this._dio);

  Future<void> addEntry({required String body}) async {
    try {
      await _dio.post('/journal', data: {'body': body});
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfterRaw = e.response?.data?['retry_after'] as String?;
        if (retryAfterRaw != null) {
          throw JournalCooldownException(DateTime.parse(retryAfterRaw));
        }
      }
      rethrow;
    }
  }

  /// Whole archive, newest first.
  Future<List<JournalEntry>> list() async {
    final response = await _dio.get('/journal');
    return (response.data as List<dynamic>)
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
