import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/session/session_bootstrap.dart';
import 'core/storage/local_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Must resolve before the first frame: every API call needs a bearer
  // token, and there is no "loading" state in the UI for "not signed in
  // yet" — see core/session/session_bootstrap.dart.
  await ensureSession(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MentalAiApp(),
    ),
  );
}
