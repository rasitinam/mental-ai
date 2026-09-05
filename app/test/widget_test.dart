import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental_ai/app/app.dart';
import 'package:mental_ai/core/constants/app_constants.dart';
import 'package:mental_ai/core/storage/local_prefs.dart';

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // No stored session (default in a fresh test) → the router's
    // redirect logic should land on /login rather than the app shell.
    expect(find.text('Hesabına giriş yap'), findsOneWidget);
  });

  testWidgets('shows the app shell when a session is already stored', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsUserIdKey: 'test-user-id',
      AppConstants.prefsSessionTokenKey: 'test-token',
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    // Mirrors what main.dart does before runApp: load whatever session is
    // already on disk into the in-memory provider the router reads.
    final existing = readStoredSession(prefs);
    container.read(sessionTokenProvider.notifier).state = existing?.token;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Günlük Rapor'), findsOneWidget);
  });
}
