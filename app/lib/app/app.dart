import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/locale_controller.dart';
import '../core/theme/theme_mode_controller.dart';
import '../core/ui/keyboard.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/glass.dart';

class MentalAiApp extends ConsumerWidget {
  const MentalAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hearth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeControllerProvider),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(appRouterProvider),
      // Paints the app's one constant canvas behind every route, so
      // glass surfaces always sit on the same backdrop instead of each
      // screen picking its own background color.
      builder: (context, child) {
        final page = DismissKeyboardOnTap(
          child: AppBackground(child: child ?? const SizedBox.shrink()),
        );
        // Nothing here sets the status bar style (there are no app bars), and
        // iOS then follows the phone's appearance rather than the app's: a dark
        // app on a light phone showed a black clock on a dark screen.
        if (defaultTargetPlatform != TargetPlatform.iOS) return page;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: page,
        );
      },
    );
  }
}
