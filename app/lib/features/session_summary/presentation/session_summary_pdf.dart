import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/app_localizations.dart';
import '../data/session_summary_api.dart';
import 'session_summary_screen.dart' show sessionBandLabel;

// Print colors, fixed rather than theme-derived: this is a document someone
// hands over or prints, and it has to read the same whatever theme the app
// happened to be in when it was made.
const _ink = PdfColor.fromInt(0xFF1E231D);
const _muted = PdfColor.fromInt(0xFF60675D);
const _accent = PdfColor.fromInt(0xFF5E7A57);
const _warning = PdfColor.fromInt(0xFFB5563E);
const _rule = PdfColor.fromInt(0xFFDDE2D8);
const _soft = PdfColor.fromInt(0xFFEEF2EA);

/// Builds the shareable A4 version of a [SessionSummary] — the same
/// sections, in the same order, as the on-screen document card.
///
/// Uses the app's own bundled fonts rather than the PDF standard fonts:
/// Helvetica has no glyphs for ş, ğ or ı, and a Turkish summary rendered
/// with blanks where those letters should be would be worse than none.
Future<Uint8List> buildSessionSummaryPdf({
  required SessionSummary summary,
  required AppLocalizations l10n,
  required String locale,
}) async {
  final body = pw.Font.ttf(await rootBundle.load('assets/fonts/InstrumentSans-Variable.ttf'));
  final heading = pw.Font.ttf(await rootBundle.load('assets/fonts/Sora-Variable.ttf'));

  final range = '${DateFormat.MMMd(locale).format(summary.periodStart.toLocal())} – '
      '${DateFormat.yMMMd(locale).format(summary.periodEnd.toLocal())}';

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: body, bold: heading),
    title: l10n.sessionDocTitle,
    author: 'Hearth',
  );

  pw.Widget sectionTitle(String text, {PdfColor color = _accent, String? trailing}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                text.toUpperCase(),
                style: pw.TextStyle(font: heading, fontSize: 8.5, letterSpacing: 1.1, color: color),
              ),
            ),
            if (trailing != null) pw.Text(trailing, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          ],
        ),
      );

  pw.Widget paragraph(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3, color: _ink));

  pw.Widget bullets(List<String> items, PdfColor color) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(top: 5, right: 8),
                    decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                  ),
                  pw.Expanded(
                    child: pw.Text(item, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2.5, color: _ink)),
                  ),
                ],
              ),
            ),
        ],
      );

  final screening = summary.screening;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(52, 46, 52, 40),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(l10n.sessionPdfFooter, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            pw.Text('${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
          ],
        ),
      ),
      build: (context) => [
        pw.Text('HEARTH', style: pw.TextStyle(font: heading, fontSize: 8.5, letterSpacing: 2, color: _accent)),
        pw.SizedBox(height: 6),
        pw.Text(l10n.sessionDocTitle, style: pw.TextStyle(font: heading, fontSize: 21, color: _ink)),
        pw.SizedBox(height: 4),
        pw.Text(
          '$range  ·  ${l10n.sessionStats(summary.moodDays, summary.journalEntries)}',
          style: const pw.TextStyle(fontSize: 9.5, color: _muted),
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 1, color: _rule),
        sectionTitle(l10n.sessionOverview),
        paragraph(summary.overview),
        if (summary.moodCourse.isNotEmpty) ...[
          sectionTitle(l10n.sessionMoodCourse),
          paragraph(summary.moodCourse),
        ],
        if (summary.themes.isNotEmpty) ...[
          sectionTitle(l10n.sessionThemes),
          bullets(summary.themes, _accent),
        ],
        if (summary.hardMoments.isNotEmpty) ...[
          sectionTitle(l10n.sessionHardMoments, color: _warning),
          bullets(summary.hardMoments, _warning),
        ],
        if (summary.whatHelped.isNotEmpty) ...[
          sectionTitle(l10n.sessionWhatHelped),
          bullets(summary.whatHelped, _accent),
        ],
        if (summary.questionsToBring.isNotEmpty) ...[
          sectionTitle(l10n.sessionQuestions),
          bullets(summary.questionsToBring, _accent),
        ],
        if (screening != null) ...[
          sectionTitle(l10n.sessionScreening, trailing: l10n.sessionScreeningAgo(screening.daysAgo)),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(
              children: [
                for (final row in [
                  (l10n.sessionScreeningDepression, '${screening.phq9Score}/27', screening.depressionBand),
                  (l10n.sessionScreeningAnxiety, '${screening.gad7Score}/21', screening.anxietyBand),
                  (l10n.sessionScreeningWellbeing, '${screening.who5Score}/25', screening.wellbeingBand),
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text(row.$1, style: const pw.TextStyle(fontSize: 10, color: _ink))),
                        pw.SizedBox(
                          width: 44,
                          child: pw.Text(row.$2, style: pw.TextStyle(font: heading, fontSize: 10, color: _ink)),
                        ),
                        pw.SizedBox(
                          width: 110,
                          child: pw.Text(sessionBandLabel(l10n, row.$3),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 10, color: _accent)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}
