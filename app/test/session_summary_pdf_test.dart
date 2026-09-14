import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';

import '../lib/features/session_summary/data/session_summary_api.dart';
import '../lib/features/session_summary/presentation/session_summary_pdf.dart';
import '../lib/l10n/app_localizations.dart';

/// The PDF is the one part of the session summary a person hands to
/// someone else, and the PDF standard fonts have no ş, ğ or ı — so this
/// renders a Turkish summary with the app's bundled fonts end to end and
/// leaves the file in `build/` for a look.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session summary PDF renders a Turkish summary with the bundled fonts', () async {
    await initializeDateFormatting('tr');
    final l10n = lookupAppLocalizations(const Locale('tr'));

    final summary = SessionSummary(
      periodStart: DateTime(2026, 9, 1),
      periodEnd: DateTime(2026, 9, 15),
      moodDays: 9,
      journalEntries: 4,
      overview:
          'Bu iki hafta işteki gerginlik yüzünden ağır geçti; uyku düzenim bozuldu. Akşam yürüyüşleri ve arkadaşımla konuşmak ise iyi geldi.',
      moodCourse: 'İlk hafta çoğunlukla düşüktü, ikinci haftanın sonuna doğru biraz toparlandım.',
      themes: const ['İş yükü ve yöneticimle gerginlik', 'Uykuya dalmakta zorlanma', 'Yalnızlık hissi'],
      hardMoments: const ['İkinci haftanın başında gece boyunca çok kaygılıydım.'],
      whatHelped: const ['Akşam yürüyüşleri', 'Günlüğe yazmak'],
      questionsToBring: const ['Uyku düzenimi nasıl toparlayabilirim?', 'İşteki kaygıyla nasıl başa çıkabilirim?'],
      screening: const SessionScreening(
        daysAgo: 12,
        phq9Score: 11,
        depressionBand: 'moderate',
        gad7Score: 9,
        anxietyBand: 'mild',
        who5Score: 12,
        wellbeingBand: 'low',
      ),
    );

    final bytes = await buildSessionSummaryPdf(summary: summary, l10n: l10n, locale: 'tr');

    expect(bytes.length, greaterThan(2000));
    Directory('build').createSync(recursive: true);
    File('build/session_summary_sample.pdf').writeAsBytesSync(bytes);
  });

  test('both bundled fonts actually contain the Turkish letters', () async {
    const turkish = 'şŞğĞıİüÜöÖçÇ';
    for (final asset in ['assets/fonts/InstrumentSans-Variable.ttf', 'assets/fonts/Sora-Variable.ttf']) {
      final parser = TtfParser((await rootBundle.load(asset)));
      final missing = [
        for (final rune in turkish.runes)
          if ((parser.charToGlyphIndexMap[rune] ?? 0) == 0) String.fromCharCode(rune),
      ];
      expect(missing, isEmpty, reason: '$asset is missing glyphs for ${missing.join()}');
    }
  });
}
