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
  // Three separate error surfaces, because Flutter has three separate ways
  // an exception can reach the top without anyone catching it first:
  //
  // - FlutterError.onError: thrown *during a widget build/layout/paint*
  //   (a null check on data that hasn't loaded yet, a bad index into a
  //   list). Flutter's own default already stops this from taking down
  //   the whole app — it fails just the one widget — but the default
  //   failure is a bright red screen of technical detail, which is a
  //   fine debugging aid and a bad thing for a released app to show
  //   someone. `ErrorWidget.builder` below replaces that box.
  // - PlatformDispatcher.instance.onError: everything *outside* a widget
  //   build — a `Future` nobody awaited, a callback, a stream listener.
  //   Uncaught here, this one genuinely terminates the isolate. Returning
  //   `true` tells the engine "handled", which is what keeps this from
  //   being an actual crash.
  // - runZonedGuarded: the outermost net, for whatever either of the
  //   above still doesn't cover (this is also the officially recommended
  //   shape for Flutter's own crash-reporting integrations, e.g.
  //   Crashlytics/Sentry, so adding one later is just adding a call
  //   inside these three handlers, not restructuring startup).
  //
  // None of this is a substitute for handling errors where they happen —
  // see `core/network/error_messages.dart` for what every network call in
  // the app actually shows someone instead of a stack trace — it's what
  // stops the *unexpected* ones (a bug, not "the wifi dropped") from
  // reading as the app being broken rather than one screen having a
  // problem.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const _FallbackErrorView();
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  runZonedGuarded(() async {
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
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

/// What a broken widget shows in place of Flutter's default red error box,
/// once the app is actually released — plain enough to need no
/// `BuildContext`-dependent localization (this is the one screen in the
/// app that has to assume nothing about what else is working), visible
/// enough that a person knows to back out rather than stare at a blank
/// area wondering if it's still loading.
class _FallbackErrorView extends StatelessWidget {
  const _FallbackErrorView();

  @override
  Widget build(BuildContext context) {
    // Matches `app/theme/app_colors.dart`'s own light-theme canvas/text
    // colors directly rather than reading `AppPalette.of(context)` — this
    // widget stands in for whatever broke, so it can't assume the
    // ancestor that would normally provide the palette is intact.
    return const ColoredBox(
      color: Color(0xFFF5F6F2),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Icon(Icons.refresh_rounded, color: Color(0xFF666C63), size: 28),
        ),
      ),
    );
  }
}
