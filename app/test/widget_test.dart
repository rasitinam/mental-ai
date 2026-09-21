import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental_ai/app/app.dart';
import 'package:mental_ai/core/constants/app_constants.dart';
import 'package:mental_ai/core/network/api_client.dart';
import 'package:mental_ai/core/storage/local_prefs.dart';
import 'package:mental_ai/app/theme/glass.dart';
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
  appleSignInTests();
  emailCodeTests();

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

/// Pumps the signed-out login screen in Turkish, on the platform under test.
Future<void> _pumpLogin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
    AppConstants.prefsLanguageKey: 'tr',
  });
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
}

void appleSignInTests() {
  testWidgets('login screen has no Sign in with Apple button on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pumpLogin(tester);
      expect(find.text('Apple ile devam et'), findsNothing);
    } finally {
      // Must be reset inside the body: the framework checks it before
      // teardown callbacks run.
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('login screen offers Sign in with Apple on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pumpLogin(tester);
      expect(find.text('Apple ile devam et'), findsOneWidget);
      expect(find.text('veya'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// Answers the two sign-up calls the way the backend does, and remembers what
/// was sent: the code request succeeds, and registering succeeds only with the
/// code `123456`.
class _SignUpAdapter implements HttpClientAdapter {
  final requests = <String, Map<String, dynamic>>{};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = (options.data as Map).cast<String, dynamic>();
    requests[options.path] = body;
    ResponseBody json(int status, String text) => ResponseBody.fromString(
          text,
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    if (options.path == '/auth/register/code') {
      return json(200, '{"resend_after_seconds":60,"expires_in_seconds":600}');
    }
    if (options.path == '/auth/register') {
      return body['code'] == '123456'
          ? json(
              200,
              '{"user_id":"11111111-1111-1111-1111-111111111111","token":"t","expires_at":"2099-01-01T00:00:00Z"}',
            )
          : json(422, '"incorrect verification code"');
    }
    throw DioException.connectionError(requestOptions: options, reason: 'unexpected call');
  }
}

void emailCodeTests() {
  testWidgets('registering asks for the emailed code before creating the account', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsPrivacyAcceptedKey: privacyPolicyVersion,
      AppConstants.prefsLanguageKey: 'tr',
    });
    final prefs = await SharedPreferences.getInstance();
    final adapter = _SignUpAdapter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
        ],
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Hesap oluştur'));
    await tester.pumpAndSettle();
    // Name, email, password.
    await tester.enterText(find.byType(TextField).at(1), 'kisi@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'sifre12345');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    // The code went out, and no account was created yet.
    expect(adapter.requests['/auth/register/code']?['email'], 'kisi@example.com');
    expect(adapter.requests.containsKey('/auth/register'), isFalse);
    expect(find.text('E-postanı doğrula'), findsOneWidget);
    expect(find.textContaining('kisi@example.com'), findsOneWidget);
    expect(find.textContaining('sn sonra yeni kod'), findsOneWidget);

    // A wrong code is refused with a message that says so.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(adapter.requests['/auth/register']?['code'], '000000');
    expect(find.text('Kod hatalı ya da süresi dolmuş.'), findsOneWidget);

    // Going back keeps what was typed, and stops the resend countdown.
    await tester.tap(find.text('Başka bir e-posta kullan'));
    await tester.pumpAndSettle();
    expect(find.text('Hesabını oluştur'), findsOneWidget);
    expect(find.text('kisi@example.com'), findsOneWidget);
  });
}
