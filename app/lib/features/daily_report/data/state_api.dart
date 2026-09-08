import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_state.dart';

final stateApiProvider = Provider<StateApi>((ref) => StateApi(ref.watch(apiClientProvider)));

class StateApi {
  final Dio _dio;
  StateApi(this._dio);

  /// The last assessment, without spending an LLM call. `null` before the
  /// first refresh.
  Future<UserState?> latest() async {
    final response = await _dio.get('/state');
    if (response.data == null) return null;
    return UserState.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reassesses from every current signal. This is what pull-to-refresh
  /// calls: the point is that a conversation the person just had should move
  /// the reading, which a cache read can't do.
  Future<UserState> refresh() async {
    final response = await _dio.post('/state/refresh');
    return UserState.fromJson(response.data as Map<String, dynamic>);
  }
}
