import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental_ai/app/app.dart';
import 'package:mental_ai/core/storage/local_prefs.dart';

void main() {
  testWidgets('onboarding screen renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MentalAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Günlük Rapor'), findsOneWidget);
  });
}
