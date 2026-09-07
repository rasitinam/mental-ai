import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/disorder_category.dart';
import '../domain/disorder_explainer.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(apiClientProvider)));

class CatalogApi {
  final Dio _dio;
  CatalogApi(this._dio);

  Future<List<DisorderCategory>> categories() async {
    final response = await _dio.get('/catalog');
    return (response.data as List<dynamic>)
        .map((e) => DisorderCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The first request for a condition generates the explainer server-side
  /// (an LLM call), later ones are served from its cache — so this can be
  /// slow once per condition and instant afterwards.
  Future<DisorderExplainer> explainer(String slug) async {
    final response = await _dio.get('/catalog/disorders/$slug');
    return DisorderExplainer.fromJson(response.data as Map<String, dynamic>);
  }
}

/// The catalog is static reference data, so it's fetched once and kept for
/// the app's lifetime rather than re-fetched per screen.
final categoriesProvider = FutureProvider<List<DisorderCategory>>((ref) async {
  return ref.watch(catalogApiProvider).categories();
});

final explainerProvider = FutureProvider.family<DisorderExplainer, String>((ref, slug) async {
  return ref.watch(catalogApiProvider).explainer(slug);
});
