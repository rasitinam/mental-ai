import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/life_story.dart';

final lifeStoriesApiProvider =
    Provider<LifeStoriesApi>((ref) => LifeStoriesApi(ref.watch(apiClientProvider)));

/// A story's body translated into the caller's own account language.
/// `autoDispose.family` — same shape as `userAvatarProvider` — so a
/// translation is fetched once per story while its card is on screen and
/// dropped once it scrolls away, rather than every story in a long feed
/// being translated up front.
final storyTranslationProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, storyId) => ref.watch(lifeStoriesApiProvider).translate(storyId),
);

class LifeStoriesApi {
  final Dio _dio;
  LifeStoriesApi(this._dio);

  /// The public guide feed — approved stories only, identity stripped by
  /// the backend before it ever reaches this response.
  Future<List<LifeStory>> feed() async {
    final response = await _dio.get('/stories');
    return (response.data as List<dynamic>)
        .map((e) => LifeStory.fromPublicJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The caller's own submissions, whatever their status.
  Future<List<LifeStory>> mine() async {
    final response = await _dio.get('/stories/mine');
    return (response.data as List<dynamic>)
        .map((e) => LifeStory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `consent` must be explicit and `diagnosisSlug` non-empty — the
  /// backend rejects the submission without either. See
  /// `StorySubmitScreen`'s checkbox and diagnosis picker.
  Future<void> submit({
    required String body,
    required String diagnosisSlug,
    required bool consent,
    required bool anonymous,
  }) async {
    await _dio.post('/stories', data: {
      'body': body,
      'diagnosis_slug': diagnosisSlug,
      'consent': consent,
      'anonymous': anonymous,
    });
  }

  /// Translates a story into the caller's own account language — the
  /// backend decides the target from the signed-in user, never a
  /// language the client passes, so this can't be repurposed as a
  /// free-form translation proxy. Cached server-side per (story,
  /// language); cheap to call again.
  Future<String> translate(String id) async {
    final response = await _dio.get('/stories/$id/translate');
    return (response.data as Map<String, dynamic>)['body'] as String;
  }

  Future<void> setUpvote(String id, {required bool upvoted}) async {
    if (upvoted) {
      await _dio.post('/stories/$id/upvote');
    } else {
      await _dio.delete('/stories/$id/upvote');
    }
  }

  Future<void> withdraw(String id) async {
    await _dio.delete('/stories/$id');
  }

  Future<void> report(String id, {String? note}) async {
    await _dio.post('/stories/$id/report', data: {'note': ?note});
  }

  /// Admin-only; the backend returns 403 for anyone else.
  Future<List<AdminStoryView>> pending() async {
    final response = await _dio.get('/stories/pending');
    return (response.data as List<dynamic>)
        .map((e) => AdminStoryView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReportedStory>> reports() async {
    final response = await _dio.get('/stories/reports');
    return (response.data as List<dynamic>)
        .map((e) => ReportedStory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String id) async {
    await _dio.post('/stories/$id/approve');
  }

  Future<void> reject(String id) async {
    await _dio.post('/stories/$id/reject');
  }
}
