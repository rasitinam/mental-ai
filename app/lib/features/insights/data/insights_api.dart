import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/insight.dart';

final insightsApiProvider = Provider<InsightsApi>((ref) => InsightsApi(ref.watch(apiClientProvider)));

/// One card translated into the reader's own account language. Same shape
/// as `storyTranslationProvider`: `autoDispose.family`, so a card is
/// translated once while it's on screen rather than the whole feed being
/// translated up front.
final insightTranslationProvider =
    FutureProvider.autoDispose.family<InsightTranslation, String>(
  (ref, insightId) => ref.watch(insightsApiProvider).translate(insightId),
);

class InsightsApi {
  final Dio _dio;
  InsightsApi(this._dio);

  /// Not per-account — the background research service builds one shared
  /// feed for the whole app (see `apps/server/src/routes/insights.rs`).
  /// `category` is a catalog slug; omitting it returns the unfiltered feed,
  /// which also includes cards that couldn't be categorized.
  Future<List<Insight>> recent({String? category}) async {
    final response = await _dio.get(
      '/insights',
      queryParameters: category == null ? null : {'category': category},
    );
    return (response.data as List<dynamic>).map((e) => Insight.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Translates one card into the caller's own account language. The
  /// backend picks the target from the signed-in account and caches the
  /// result per (card, language), so this is cheap after the first reader.
  Future<InsightTranslation> translate(String id) async {
    final response = await _dio.get('/insights/$id/translate');
    return InsightTranslation.fromJson(response.data as Map<String, dynamic>);
  }

  /// Manually turns already-ingested research articles into insight
  /// cards — for when the scheduled background cycle found nothing "new"
  /// (e.g. PubMed returned the same articles already fetched before) but
  /// the feed is still empty. Can genuinely return an empty list if there
  /// are no unsummarized articles left either.
  Future<List<Insight>> synthesizeNow() async {
    final response = await _dio.post('/insights/synthesize-now');
    return (response.data as List<dynamic>).map((e) => Insight.fromJson(e as Map<String, dynamic>)).toList();
  }
}
