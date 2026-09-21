import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental_ai/app/theme/app_colors.dart';
import 'package:mental_ai/app/theme/app_theme.dart';
import 'package:mental_ai/core/ui/emergency_call.dart';
import 'package:mental_ai/core/ui/keyboard.dart';
import 'package:mental_ai/l10n/app_localizations.dart';

Widget _app(Widget home, {Locale locale = const Locale('tr')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('keyboard', () {
    testWidgets('a tap on empty space hides it, a tap on the field keeps it', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _app(
          DismissKeyboardOnTap(
            child: Scaffold(
              body: Column(
                children: [
                  const TextField(),
                  const SizedBox(height: 40),
                  const Text('somewhere else'),
                  TextButton(onPressed: () => pressed++, child: const Text('press')),
                ],
              ),
            ),
          ),
        ),
      );
      final focus = () => tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus(), isTrue);

      // Tapping the field again must not close it.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus(), isTrue);

      // A button still gets its tap, and the keyboard stays for it.
      await tester.tap(find.text('press'));
      await tester.pump();
      expect(pressed, 1);
      expect(focus(), isTrue);

      await tester.tap(find.text('somewhere else'));
      await tester.pump();
      expect(focus(), isFalse);
    });

    testWidgets('dismissKeyboard() drops the focus', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: TextField(autofocus: true))));
      await tester.pump();
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);

      dismissKeyboard();
      await tester.pump();
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
    });
  });

  group('pages', () {
    test('a page is opaque, in the colour painted behind the app', () {
      // A transparent scaffold let the previous page show through it while a
      // page slid in on iOS.
      expect(AppTheme.light.scaffoldBackgroundColor, AppPalette.light.canvasTop);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppPalette.dark.canvasTop);
      expect(AppTheme.light.scaffoldBackgroundColor.a, 1.0);
      expect(AppTheme.dark.scaffoldBackgroundColor.a, 1.0);
    });
  });

  group('emergency call', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');

    testWidgets('says so when the device cannot place the call', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => false);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => callEmergency(context, '112'),
                child: const Text('call'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('call'));
      await tester.pumpAndSettle();

      expect(find.textContaining('112'), findsOneWidget);
      expect(find.textContaining('arama yapamıyor'), findsOneWidget);
    });

    testWidgets('stays quiet when the call goes through', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => true);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => callEmergency(context, '112'),
                child: const Text('call'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('call'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
