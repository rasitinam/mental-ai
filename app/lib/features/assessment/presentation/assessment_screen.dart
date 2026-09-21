import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/ui/emergency_call.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/assessment_result.dart';
import '../domain/instruments.dart';
import 'assessment_controller.dart';

/// The full screening-battery flow — seven public-domain instruments,
/// [kAssessmentQuestionCount] questions in all — reused in two places:
/// onboarding (`skippable: true`, right after registration) and Settings'
/// "retake" entry (`skippable: false`, reached via a normal back-navigable
/// route). The two only differ in the intro screen's chrome and in what
/// happens once a result comes back — the questions, scoring and crisis
/// handling are identical either way.
class AssessmentScreen extends ConsumerStatefulWidget {
  final bool skippable;
  final VoidCallback onDone;

  const AssessmentScreen({super.key, required this.skippable, required this.onDone});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(assessmentControllerProvider);
    final controller = ref.read(assessmentControllerProvider.notifier);

    Widget body;
    if (state.result != null) {
      body = _ResultView(
        key: const ValueKey('result'),
        result: state.result!,
        palette: palette,
        l10n: l10n,
        onContinue: widget.onDone,
      );
    } else if (!_started) {
      body = _IntroView(
        key: const ValueKey('intro'),
        palette: palette,
        l10n: l10n,
        showBack: !widget.skippable,
        onStart: () => setState(() => _started = true),
        onSkip: widget.skippable ? widget.onDone : null,
      );
    } else {
      body = _QuestionView(
        key: const ValueKey('question'),
        state: state,
        controller: controller,
        palette: palette,
        l10n: l10n,
        // From the very first question there is nothing to step back to
        // inside the battery, so back returns to the intro card — which
        // is where the skip link lives. Without this, tapping "Başla"
        // once and changing your mind left no way out but 48 questions.
        onBackFromFirst: () => setState(() => _started = false),
      );
    }

    return Scaffold(
      body: SafeArea(
        // The onboarding entry (`skippable: true`) is a top-level route
        // with no floating nav bar over it, so it takes the real bottom
        // inset — Android's navigation bar was otherwise clipping the
        // skip link under it. The Settings retake entry
        // (`skippable: false`) lives inside the shell and clears its
        // floating tab bar with `bottomClearance` instead.
        bottom: widget.skippable,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, widget.skippable ? 24 : bottomClearance(context)),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: body),
        ),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;
  final bool showBack;
  final VoidCallback onStart;
  final VoidCallback? onSkip;

  const _IntroView({
    super.key,
    required this.palette,
    required this.l10n,
    required this.showBack,
    required this.onStart,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBack)
          Row(children: [
            SquareIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ]),
        SizedBox(height: showBack ? 22 : 48),
        Text(l10n.assessmentOnboardTitle, style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
        const SizedBox(height: 10),
        Text(l10n.assessmentOnboardIntro(kAssessmentQuestionCount),
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
        const Spacer(),
        AppPrimaryButton(label: l10n.assessmentStart, onPressed: onStart),
        if (onSkip != null) ...[
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.assessmentSkip,
                    style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Locates which instrument (and which of its questions) a flat step
/// index falls in — the flow is one long sequence of questions, but each
/// screen still needs to know which section label and intro line to show.
({AssessmentInstrument instrument, AssessmentQuestion question, int localIndex}) _questionAt(
  List<AssessmentInstrument> instruments,
  int step,
) {
  var offset = 0;
  for (final instrument in instruments) {
    if (step < offset + instrument.questions.length) {
      return (
        instrument: instrument,
        question: instrument.questions[step - offset],
        localIndex: step - offset,
      );
    }
    offset += instrument.questions.length;
  }
  throw RangeError.index(step, instruments, 'step');
}

class _QuestionView extends StatelessWidget {
  final AssessmentState state;
  final AssessmentController controller;
  final AppPalette palette;
  final AppLocalizations l10n;

  /// Where back goes on the first question — see `_AssessmentScreenState`.
  final VoidCallback onBackFromFirst;

  const _QuestionView({
    super.key,
    required this.state,
    required this.controller,
    required this.palette,
    required this.l10n,
    required this.onBackFromFirst,
  });

  @override
  Widget build(BuildContext context) {
    final instruments = buildInstruments(l10n);
    final located = _questionAt(instruments, state.step);
    final progress = (state.step + 1) / kAssessmentQuestionCount;
    final showIntro = located.localIndex == 0 && located.instrument.intro != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SquareIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: state.submitting
                    ? null
                    : (state.isFirstStep ? onBackFromFirst : controller.goBack),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: palette.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation(palette.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(l10n.assessmentProgress(state.step + 1, kAssessmentQuestionCount),
                style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          ),
          const SizedBox(height: 24),
          SectionLabel(located.instrument.sectionLabel, color: palette.accent),
          if (showIntro) ...[
            const SizedBox(height: 10),
            Text(located.instrument.intro!,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5)),
          ],
          const SizedBox(height: 10),
          Text(located.question.text, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 28),
          for (var i = 0; i < located.question.options.length; i++) ...[
            _AnswerOption(
              label: located.question.options[i],
              selected: state.currentAnswer == i,
              palette: palette,
              onTap: state.submitting ? null : () => controller.selectAndAdvance(i),
            ),
            if (i != located.question.options.length - 1) const SizedBox(height: 10),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(friendlyErrorMessage(l10n, state.error!), style: TextStyle(color: palette.warning)),
          ],
          if (state.submitting) ...[
            const SizedBox(height: 20),
            Center(child: CircularProgressIndicator(color: palette.accent)),
          ],
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _AnswerOption({required this.label, required this.selected, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accentSoft : palette.glassFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? palette.accent : palette.separator, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: selected ? palette.accent : palette.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, size: 20, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final AssessmentResult result;
  final AppPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onContinue;

  const _ResultView({
    super.key,
    required this.result,
    required this.palette,
    required this.l10n,
    required this.onContinue,
  });

  String _bandLabel(String band) {
    switch (band) {
      case 'minimal':
        return l10n.assessmentBandMinimal;
      case 'mild':
        return l10n.assessmentBandMild;
      case 'moderate':
        return l10n.assessmentBandModerate;
      case 'moderately severe':
        return l10n.assessmentBandModeratelySevere;
      case 'severe':
        return l10n.assessmentBandSevere;
      case 'very low':
        return l10n.assessmentBandVeryLow;
      case 'low':
        return l10n.assessmentBandLow;
      case 'medium':
        return l10n.assessmentBandMedium;
      case 'high':
        return l10n.assessmentBandHigh;
      case 'good':
        return l10n.assessmentBandGood;
      case 'caution':
        return l10n.assessmentBandCaution;
      case 'below threshold':
        return l10n.assessmentBandBelowThreshold;
      default:
        return l10n.assessmentBandPositiveScreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      (title: l10n.assessmentResultDepression, score: result.phq9Score, max: 27, band: result.depressionBand),
      (title: l10n.assessmentResultAnxiety, score: result.gad7Score, max: 21, band: result.anxietyBand),
      (title: l10n.assessmentResultWellbeing, score: result.who5Score, max: 25, band: result.wellbeingBand),
      (title: l10n.assessmentResultSomatic, score: result.phq15Score, max: 30, band: result.somaticBand),
      (title: l10n.assessmentResultPtsd, score: result.ptsd5Score, max: 5, band: result.ptsdBand),
      (title: l10n.assessmentResultAlcohol, score: result.auditcScore, max: 12, band: result.alcoholBand),
      (title: l10n.assessmentResultSubstance, score: result.cageaidScore, max: 4, band: result.substanceBand),
    ];

    // The button is a direct `Column` child, outside the
    // `SingleChildScrollView` — seven score cards is enough content that
    // it doesn't always fit on one screen, and a "Devam et" that only
    // existed at the bottom of a scrollable area reads as a missing
    // button to someone who never scrolls down. Pinning it below the
    // scroll area means it's always visible regardless of how tall the
    // card grid or the crisis banner get.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(l10n.assessmentResultTitle,
                    style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 8),
                Text(l10n.assessmentResultNote,
                    style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 44 - 12) / 2,
                        child: _ScoreCard(
                          title: card.title,
                          score: card.score,
                          max: card.max,
                          band: _bandLabel(card.band),
                          palette: palette,
                        ),
                      ),
                  ],
                ),
                if (result.crisisFlag) ...[
                  const SizedBox(height: 20),
                  _AssessmentCrisisBanner(palette: palette, l10n: l10n),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(label: l10n.assessmentContinueCta, onPressed: onContinue),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final int max;
  final String band;
  final AppPalette palette;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.max,
    required this.band,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 8),
          Text('$score/$max', style: AppTypography.title2.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(100)),
            child: Text(band,
                style: AppTypography.caption.copyWith(color: palette.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// A standalone crisis notice for the assessment result — same visual
/// language as the chat screen's per-message crisis card, but not tied to
/// a dismissible message: it's simply part of the result until the person
/// taps Continue below it.
class _AssessmentCrisisBanner extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;

  const _AssessmentCrisisBanner({required this.palette, required this.l10n});

  Future<void> _call(BuildContext context) => callEmergency(context, '112');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.warning, shape: BoxShape.circle),
                child: Text('!',
                    style: TextStyle(
                        fontSize: 11, height: 1, fontWeight: FontWeight.w700, color: palette.warningSoft)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(l10n.chatCrisisTitle,
                    style: AppTypography.footnote
                        .copyWith(color: palette.warning, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l10n.chatCrisis, style: AppTypography.footnote.copyWith(color: palette.warning)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Material(
              color: palette.warning,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _call(context),
                child: Center(
                  child: Text(l10n.chatCallEmergency,
                      style: TextStyle(color: AppPalette.of(context).warningSoft, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
