import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final journalApiProvider = Provider<JournalApi>((ref) => JournalApi(ref.watch(apiClientProvider)));

class JournalApi {
  final Dio _dio;
  JournalApi(this._dio);

  Future<void> addEntry({required String userId, required String body}) async {
    await _dio.post('/journal', data: {'user_id': userId, 'body': body});
  }
}
