import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final moodApiProvider = Provider<MoodApi>((ref) => MoodApi(ref.watch(apiClientProvider)));

class MoodApi {
  final Dio _dio;
  MoodApi(this._dio);

  Future<void> addMood({
    required double valence,
    required double arousal,
    List<String> tags = const [],
    String? note,
  }) async {
    await _dio.post('/mood', data: {
      'valence': valence,
      'arousal': arousal,
      'tags': tags,
      'note': ?note,
    });
  }
}
