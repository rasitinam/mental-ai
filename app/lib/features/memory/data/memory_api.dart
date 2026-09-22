import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'memory_models.dart';

final memoryApiProvider = Provider<MemoryApi>((ref) => MemoryApi(ref.watch(apiClientProvider)));

/// "What Hearth remembers" — the long-term memory Hearth quietly distills
/// from someone's own entries (mood notes, journal, their side of chat) so
/// later answers can be specific instead of asking the same things again.
/// It's theirs to read, pause and clear from Settings. Nothing here ever
/// calls the model directly — the memory itself is (re)written in the
/// background after ordinary activity.
class MemoryApi {
  final Dio _dio;
  MemoryApi(this._dio);

  Future<PersonMemory> get() async {
    final response = await _dio.get('/memory');
    return PersonMemory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PersonMemory> setEnabled(bool enabled) async {
    final response = await _dio.put('/memory/enabled', data: {'enabled': enabled});
    return PersonMemory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PersonMemory> clear() async {
    final response = await _dio.delete('/memory');
    return PersonMemory.fromJson(response.data as Map<String, dynamic>);
  }
}

final personMemoryProvider = FutureProvider.autoDispose<PersonMemory>((ref) {
  return ref.watch(memoryApiProvider).get();
});
