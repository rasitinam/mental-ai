import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental_ai/app/app.dart';
import 'package:mental_ai/core/constants/app_constants.dart';
import 'package:mental_ai/core/network/api_client.dart';
import 'package:mental_ai/core/storage/local_prefs.dart';

/// Fails every request immediately instead of letting the real client open
/// sockets and leave connect-timeout timers pending past the end of a test.
/// The screens under test only need to route and render; what the API would
/// have returned isn't what's being asserted.
class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(requestOptions: options, reason: 'offline in tests');
  }
}

Dio _offlineDio() => Dio()..httpClientAdapter = _OfflineAdapter();

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    // The language is pinned so the assertions below test routing, not
    // whatever locale the test host happens to report.
    SharedPreferences.setMockInitialValues({AppConstants.prefsLanguageKey: 'tr'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(_offlineDio()),
        ],
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // No stored session (default in a fresh test) → the router's
    // redirect logic should land on /login rather than the app shell.
    expect(find.text('Tekrar hoş geldin'), findsOneWidget);
  });

  testWidgets('shows the app shell when a session is already stored', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsUserIdKey: 'test-user-id',
      AppConstants.prefsSessionTokenKey: 'test-token',
      AppConstants.prefsLanguageKey: 'tr',
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(_offlineDio()),
      ],
    );
    // Mirrors what main.dart does before runApp: load whatever session is
    // already on disk into the in-memory provider the router reads.
    final existing = readStoredSession(prefs);
    container.read(sessionTokenProvider.notifier).state = existing?.token;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MentalAiApp()),
    );
    await tester.pumpAndSettle();

    // The home screen greets by time of day rather than carrying a title
    // bar, so the greeting is what proves the shell rendered. Every network
    // call fails in a test, which is fine — routing is what's under test.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            const {'Günaydın', 'İyi günler', 'İyi akşamlar', 'İyi geceler'}.contains(widget.data),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders in English when the stored language is English', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({AppConstants.prefsLanguageKey: 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(_offlineDio()),
        ],
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
