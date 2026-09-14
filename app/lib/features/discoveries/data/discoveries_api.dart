import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_prefs.dart';

enum DiscoveryKind { lifts, drains, rhythm }

/// One "Seni iyi hissettirenler" card — see
/// `backend/apps/server/src/routes/discoveries.rs`.
class Discovery {
  final DiscoveryKind kind;
  final String emoji;
  final String title;
  final String body;

  const Discovery({required this.kind, required this.emoji, required this.title, required this.body});

  factory Discovery.fromJson(Map<String, dynamic> json) => Discovery(
        kind: switch (json['kind'] as String?) {
          'drains' => DiscoveryKind.drains,
          'rhythm' => DiscoveryKind.rhythm,
          _ => DiscoveryKind.lifts,
        },
        emoji: json['emoji'] as String? ?? '🌿',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

/// Either not enough history yet ([locked], with how far along they are)
/// or a set of cards — which can be empty when there's history but
/// nothing honest to call a pattern.
class DiscoveriesResult {
  final bool locked;
  final int daysLogged;
  final int daysNeeded;
  final List<Discovery> cards;

  const DiscoveriesResult({
    required this.locked,
    this.daysLogged = 0,
    this.daysNeeded = 0,
    this.cards = const [],
  });

  factory DiscoveriesResult.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'locked') {
      return DiscoveriesResult(
        locked: true,
        daysLogged: json['days_logged'] as int? ?? 0,
        daysNeeded: json['days_needed'] as int? ?? 7,
      );
    }
    return DiscoveriesResult(
      locked: false,
      cards: (json['cards'] as List<dynamic>? ?? [])
          .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
          .where((d) => d.title.isNotEmpty)
          .toList(),
    );
  }
}

final discoveriesApiProvider =
    Provider<DiscoveriesApi>((ref) => DiscoveriesApi(ref.watch(apiClientProvider)));

/// Fetched once per session and shared by the home strip and the life
/// screen's full list. Not auto-disposed: the first build of the cards is
/// one LLM call the backend then caches for a day, and switching tabs
/// shouldn't replay the loading state. Watching the session resets it on
/// an account switch; pull-to-refresh invalidates it.
final discoveriesProvider = FutureProvider<DiscoveriesResult>((ref) {
  ref.watch(sessionTokenProvider);
  return ref.watch(discoveriesApiProvider).fetch();
});

class DiscoveriesApi {
  final Dio _dio;
  DiscoveriesApi(this._dio);

  Future<DiscoveriesResult> fetch() async {
    final response = await _dio.get('/discoveries');
    return DiscoveriesResult.fromJson(response.data as Map<String, dynamic>);
  }
}
