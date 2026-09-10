import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/session/session_bootstrap.dart';
import 'core/storage/local_prefs.dart';
import 'features/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  loadStoredSession(container);

  // Web needs its own Firebase web-app config, a service worker, and a
  // VAPID key — none of which exist yet, so push stays Android/iOS-only
  // for now rather than failing to initialize on every page load.
  if (!kIsWeb) {
    unawaited(container.read(pushServiceProvider).init());
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MentalAiApp(),
    ),
  );
}
