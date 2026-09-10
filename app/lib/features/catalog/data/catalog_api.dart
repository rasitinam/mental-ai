import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/api_client.dart';
import '../domain/disorder_category.dart';
import '../domain/disorder_explainer.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(apiClientProvider)));

class CatalogApi {
  final Dio _dio;
  CatalogApi(this._dio);

  /// `lang` rather than the account's stored language: the catalog is
  /// unauthenticated reference data the app needs before a session exists,
  /// so the caller states which language it wants.
  Future<List<DisorderCategory>> categories(String language) async {
    final response = await _dio.get('/catalog', queryParameters: {'lang': language});
    return (response.data as List<dynamic>)
        .map((e) => DisorderCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The first request for a condition *in a given language* generates the
  /// explainer server-side (an LLM call), later ones are served from its
  /// cache — so this can be slow once per condition and instant afterwards.
  Future<DisorderExplainer> explainer(String slug, String language) async {
    final response =
        await _dio.get('/catalog/disorders/$slug', queryParameters: {'lang': language});
    return DisorderExplainer.fromJson(response.data as Map<String, dynamic>);
  }
}

/// The catalog is static reference data, so it's fetched once and kept
/// rather than re-fetched per screen — but it *is* language-specific, so
/// watching the locale means switching language refetches the tree instead
/// of leaving condition names in the old one.
final categoriesProvider = FutureProvider<List<DisorderCategory>>((ref) async {
  final language = ref.watch(localeControllerProvider).languageCode;
  return ref.watch(catalogApiProvider).categories(language);
});

final explainerProvider = FutureProvider.family<DisorderExplainer, String>((ref, slug) async {
  final language = ref.watch(localeControllerProvider).languageCode;
  return ref.watch(catalogApiProvider).explainer(slug, language);
});
