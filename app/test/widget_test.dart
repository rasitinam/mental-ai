import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental_ai/app/app.dart';
import 'package:mental_ai/core/constants/app_constants.dart';
import 'package:mental_ai/core/network/api_client.dart';
import 'package:mental_ai/core/storage/local_prefs.dart';
import 'package:mental_ai/features/consent/presentation/privacy_consent_screen.dart';

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
    SharedPreferences.setMockInitialValues({AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
      AppConstants.prefsLanguageKey: 'tr'});
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

  testWidgets('opens on the story feed when a session is already stored', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsUserIdKey: 'test-user-id',
      AppConstants.prefsSessionTokenKey: 'test-token',
      AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
      AppConstants.prefsLanguageKey: 'tr',
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(_offlineDio()),
      ],
    );
    // A manually-created container isn't torn down by the widget tree the
    // way `ProviderScope`'s own container would be — without this, any
    // provider holding a live resource (e.g. `dmBadgeProvider`'s poll
    // timer) leaks past the end of the test.
    addTearDown(container.dispose);
    // Mirrors what main.dart does before runApp: load whatever session is
    // already on disk into the in-memory provider the router reads.
    final existing = readStoredSession(prefs);
    container.read(sessionTokenProvider.notifier).state = existing?.token;

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MentalAiApp()),
    );
    await tester.pumpAndSettle();

    // The feed is the landing screen for a signed-in account, so its
    // title is what proves both the shell and the right initial branch.
    // Every network call fails in a test, which is fine — routing is
    // what's under test, not what the feed would have contained.
    expect(find.text('Hikayeler'), findsWidgets);

    // `addTearDown` runs after the test body's own pending-timer check —
    // too late to stop `dmBadgeProvider`'s poll timer from tripping it —
    // so this container needs disposing here, synchronously, not just
    // registered for later.
    container.dispose();
  });

  testWidgets('renders in English when the stored language is English', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
      AppConstants.prefsLanguageKey: 'en'});
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

  testWidgets('switching to register shows the display name field', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
      AppConstants.prefsLanguageKey: 'tr'});
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

    // The name field only makes sense once someone is actually creating an
    // account — it shouldn't be visible on the login form.
    expect(find.text('Adın'), findsNothing);

    // The toggle is a Text.rich ("Hesabın yok mu? " + "Hesap oluştur"
    // spans), so it has to be matched by contained text rather than an
    // exact `Text`.
    await tester.tap(find.textContaining('Hesap oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Hesabını oluştur'), findsOneWidget);
    expect(find.text('Adın'), findsOneWidget);
  });

  testWidgets('shows the privacy summary first and continues to login once slid to accept', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Başlamadan önce'), findsOneWidget);

    // Letting go early slides the handle back without accepting.
    final slider = find.byType(SlideToAccept);
    await tester.drag(slider, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.text('Başlamadan önce'), findsOneWidget);
    expect(prefs.getString(AppConstants.prefsPrivacyAcceptedKey), isNull);

    await tester.drag(slider, const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar hoş geldin'), findsOneWidget);
    expect(prefs.getString(AppConstants.prefsPrivacyAcceptedKey), privacyPolicyVersion);
  });
}
