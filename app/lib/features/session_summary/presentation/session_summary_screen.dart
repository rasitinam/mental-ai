import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../data/session_summary_api.dart';
import 'session_summary_pdf.dart';

/// Must match `ALLOWED_DAYS` in `backend/apps/server/src/routes/session_summary.rs`.
const _periods = [7, 14, 30];

/// Same wording the assessment result screen uses for each band, so a
/// score reads the same here as where it was first shown.
String sessionBandLabel(AppLocalizations l10n, String band) => switch (band) {
      'minimal' => l10n.assessmentBandMinimal,
      'mild' => l10n.assessmentBandMild,
      'moderate' => l10n.assessmentBandModerate,
      'moderately severe' => l10n.assessmentBandModeratelySevere,
      'severe' => l10n.assessmentBandSevere,
      'very low' => l10n.assessmentBandVeryLow,
      'low' => l10n.assessmentBandLow,
      'medium' => l10n.assessmentBandMedium,
      'high' => l10n.assessmentBandHigh,
      'good' => l10n.assessmentBandGood,
      'caution' => l10n.assessmentBandCaution,
      'below threshold' => l10n.assessmentBandBelowThreshold,
      _ => l10n.assessmentBandPositiveScreen,
    };

/// "Seans öncesi özetim": pick a period, optionally say what you want to
/// bring up, get a one-page brief built from your own records, share it as
/// a PDF.
///
/// Laid out as a form that stays put above its result, not a wizard: the
/// usual next step after reading a summary is "try the last month
/// instead", and that should be one tap on the period plus Regenerate,
/// not a trip back through steps.
class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key});

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  final _note = TextEditingController();
  final _resultKey = GlobalKey();
  int _days = 14;
  bool _loading = false;
  bool _sharing = false;
  Object? _error;
  SessionSummary? _summary;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await ref.read(sessionSummaryApiProvider).generate(days: _days, note: _note.text);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
      HapticFeedback.lightImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _resultKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
        }
      });
    } on NotEnoughRecordsException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.sessionNotEnough;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _share(SessionSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _sharing = true);
    try {
      final bytes = await buildSessionSummaryPdf(summary: summary, l10n: l10n, locale: locale);
      final stamp = DateFormat('yyyy-MM-dd').format(summary.periodEnd);
      final file = XFile.fromData(bytes, name: 'hearth-seans-ozeti-$stamp.pdf', mimeType: 'application/pdf');
      await Share.shareXFiles([file], subject: l10n.sessionDocTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(l10n, e))));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final summary = _summary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          children: [
            Row(
              children: [
                SquareIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(l10n.sessionTitle,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(l10n.sessionIntro,
                style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.55)),
            const SizedBox(height: 24),
            SectionLabel(l10n.sessionPeriodLabel),
            const SizedBox(height: 10),
            _PeriodSelector(
              selected: _days,
              palette: palette,
              labels: {
                7: l10n.sessionPeriodWeek,
                14: l10n.sessionPeriodTwoWeeks,
                30: l10n.sessionPeriodMonth,
              },
              onChanged: _loading ? null : (days) => setState(() => _days = days),
            ),
            const SizedBox(height: 22),
            SectionLabel(l10n.sessionNoteLabel),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: palette.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.separator),
              ),
              child: TextField(
                controller: _note,
                enabled: !_loading,
                minLines: 2,
                maxLines: 5,
                maxLength: 600,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
                cursorColor: palette.accent,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.sessionNoteHint,
                  hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
                  counterStyle: AppTypography.caption.copyWith(color: palette.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Text(
                friendlyErrorMessage(l10n, _error!),
                style: AppTypography.footnote.copyWith(color: palette.warning, height: 1.5),
              ),
              const SizedBox(height: 12),
            ],
            AppPrimaryButton(
              label: summary == null ? l10n.sessionGenerate : l10n.sessionRegenerate,
              icon: summary == null ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
              loading: _loading,
              onPressed: _loading ? null : _generate,
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              _GeneratingCard(palette: palette, l10n: l10n),
            ],
            if (summary != null && !_loading) ...[
              const SizedBox(height: 28),
              KeyedSubtree(
                key: _resultKey,
                child: _SummaryDocument(summary: summary, palette: palette, l10n: l10n),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: l10n.sessionShare,
                icon: Icons.ios_share_rounded,
                loading: _sharing,
                onPressed: _sharing ? null : () => _share(summary),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.sessionDisclaimer,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: palette.textTertiary, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final AppPalette palette;
  final Map<int, String> labels;
  final ValueChanged<int>? onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.palette,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final days in _periods)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: days == selected ? palette.glassFill : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: days == selected ? palette.separator : Colors.transparent),
                  ),
                  child: Text(
                    labels[days] ?? '$days',
                    style: AppTypography.footnote.copyWith(
                      color: days == selected ? palette.textPrimary : palette.textSecondary,
                      fontWeight: days == selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneratingCard extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;

  const _GeneratingCard({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 18,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: palette.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.sessionGenerating,
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(l10n.sessionGeneratingBody,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The summary rendered as a document card — the same sections, in the
/// same order, as the PDF it shares, so what someone reads on screen is
/// exactly what their therapist will get.
class _SummaryDocument extends StatelessWidget {
  final SessionSummary summary;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _SummaryDocument({required this.summary, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final range = '${DateFormat.MMMd(locale).format(summary.periodStart.toLocal())} – '
        '${DateFormat.yMMMd(locale).format(summary.periodEnd.toLocal())}';

    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.assignment_outlined, size: 21, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sessionDocTitle,
                        style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(range, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.sessionStats(summary.moodDays, summary.journalEntries),
            style: AppTypography.caption.copyWith(color: palette.textTertiary),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: palette.separator),
          _Section(title: l10n.sessionOverview, palette: palette, child: _Paragraph(summary.overview, palette)),
          if (summary.moodCourse.isNotEmpty)
            _Section(title: l10n.sessionMoodCourse, palette: palette, child: _Paragraph(summary.moodCourse, palette)),
          if (summary.themes.isNotEmpty)
            _Section(
              title: l10n.sessionThemes,
              palette: palette,
              child: _Bullets(items: summary.themes, color: palette.accent, palette: palette),
            ),
          if (summary.hardMoments.isNotEmpty)
            _Section(
              title: l10n.sessionHardMoments,
              palette: palette,
              titleColor: palette.warning,
              child: _Bullets(items: summary.hardMoments, color: palette.warning, palette: palette),
            ),
          if (summary.whatHelped.isNotEmpty)
            _Section(
              title: l10n.sessionWhatHelped,
              palette: palette,
              child: _Bullets(items: summary.whatHelped, color: palette.accentAlt, palette: palette),
            ),
          if (summary.questionsToBring.isNotEmpty)
            _Section(
              title: l10n.sessionQuestions,
              palette: palette,
              child: _Bullets(
                items: summary.questionsToBring,
                color: palette.accent,
                palette: palette,
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ),
          if (summary.screening != null)
            _Section(
              title: l10n.sessionScreening,
              trailing: l10n.sessionScreeningAgo(summary.screening!.daysAgo),
              palette: palette,
              child: _ScreeningTable(screening: summary.screening!, palette: palette, l10n: l10n),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? titleColor;
  final AppPalette palette;
  final Widget child;

  const _Section({
    required this.title,
    required this.palette,
    required this.child,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(title, color: titleColor ?? palette.accent)),
              if (trailing != null)
                Text(trailing!, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _Paragraph(this.text, this.palette);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.subheadline.copyWith(color: palette.textPrimary, height: 1.6));
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  final Color color;
  final AppPalette palette;
  final IconData? icon;

  const _Bullets({required this.items, required this.color, required this.palette, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: icon == null
                      ? Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                      : Icon(icon, size: 13, color: color),
                ),
                SizedBox(width: icon == null ? 11 : 9),
                Expanded(
                  child: Text(item,
                      style: AppTypography.subheadline.copyWith(color: palette.textPrimary, height: 1.5)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScreeningTable extends StatelessWidget {
  final SessionScreening screening;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _ScreeningTable({required this.screening, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (label: l10n.sessionScreeningDepression, score: '${screening.phq9Score}/27', band: screening.depressionBand),
      (label: l10n.sessionScreeningAnxiety, score: '${screening.gad7Score}/21', band: screening.anxietyBand),
      (label: l10n.sessionScreeningWellbeing, score: '${screening.who5Score}/25', band: screening.wellbeingBand),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(row.label, style: AppTypography.footnote.copyWith(color: palette.textPrimary)),
                ),
                Text(
                  row.score,
                  style: AppTypography.footnote.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    sessionBandLabel(l10n, row.band),
                    style: AppTypography.caption.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
