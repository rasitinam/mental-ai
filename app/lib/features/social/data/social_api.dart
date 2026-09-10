import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/social_models.dart';

final socialApiProvider = Provider<SocialApi>((ref) => SocialApi(ref.watch(apiClientProvider)));

/// Someone else's profile. `family` because several screens can be
/// looking at different people at once (a feed author, then whoever they
/// follow), and `autoDispose` so a profile stops being cached the moment
/// nothing is showing it.
final publicProfileProvider = FutureProvider.autoDispose.family<PublicProfile, String>(
  (ref, userId) => ref.watch(socialApiProvider).profile(userId),
);

/// Another account's avatar bytes, fetched through the same authenticated
/// client as everything else rather than an `Image.network` that would
/// have to carry the bearer token itself.
final userAvatarProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, userId) => ref.watch(socialApiProvider).avatar(userId),
);

final dmThreadsProvider = FutureProvider.autoDispose<List<DmThread>>(
  (ref) => ref.watch(socialApiProvider).threads(),
);

final dmRequestsProvider = FutureProvider.autoDispose<List<DmThread>>(
  (ref) => ref.watch(socialApiProvider).requests(),
);

final dmMessagesProvider = FutureProvider.autoDispose.family<List<DmMessage>, String>(
  (ref, threadId) => ref.watch(socialApiProvider).messages(threadId),
);

class SocialApi {
  final Dio _dio;
  SocialApi(this._dio);

  Future<PublicProfile> profile(String userId) async {
    final response = await _dio.get('/users/$userId');
    return PublicProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Uint8List?> avatar(String userId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/users/$userId/avatar',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> setFollow(String userId, {required bool following}) async {
    if (following) {
      await _dio.post('/users/$userId/follow');
    } else {
      await _dio.delete('/users/$userId/follow');
    }
  }

  Future<List<UserCard>> followers(String userId) async {
    final response = await _dio.get('/users/$userId/followers');
    return (response.data as List<dynamic>)
        .map((e) => UserCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserCard>> following(String userId) async {
    final response = await _dio.get('/users/$userId/following');
    return (response.data as List<dynamic>)
        .map((e) => UserCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DmThread>> threads() async {
    final response = await _dio.get('/dm/threads');
    return (response.data as List<dynamic>)
        .map((e) => DmThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DmThread>> requests() async {
    final response = await _dio.get('/dm/requests');
    return (response.data as List<dynamic>)
        .map((e) => DmThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DmMessage>> messages(String threadId) async {
    final response = await _dio.get('/dm/threads/$threadId/messages');
    return (response.data as List<dynamic>)
        .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Opens a conversation with its first message. Returns the thread id,
  /// which is `pending` until the other side answers.
  Future<String> openThread(String userId, String body) async {
    final response = await _dio.post('/dm/with/$userId', data: {'body': body});
    return (response.data as Map<String, dynamic>)['thread_id'] as String;
  }

  Future<void> send(String threadId, String body) async {
    await _dio.post('/dm/threads/$threadId/messages', data: {'body': body});
  }

  Future<void> accept(String threadId) async {
    await _dio.post('/dm/threads/$threadId/accept');
  }

  /// Declines a request or leaves a conversation — both delete the thread.
  Future<void> discard(String threadId) async {
    await _dio.delete('/dm/threads/$threadId');
  }
}
