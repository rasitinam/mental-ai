import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/assessment_result.dart';
import 'assessment_controller.dart';

/// The 16-question PHQ-9 + GAD-7 flow, reused in two places: onboarding
/// (`skippable: true`, right after registration) and Settings' "retake"
/// entry (`skippable: false`, reached via a normal back-navigable route).
/// The two only differ in the intro screen's chrome and in what happens
/// once a result comes back — the questions, scoring and crisis handling
/// are identical either way.
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
      body = _QuestionView(key: const ValueKey('question'), state: state, controller: controller, palette: palette, l10n: l10n);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // The onboarding entry (`skippable: true`) is a top-level route
        // with no floating nav bar over it; the Settings retake entry
        // (`skippable: false`) lives inside the shell, where `HomeShell`'s
        // floating nav bar sits over the last ~100px — same reasoning as
        // `profile_screen.dart`'s 140 bottom padding.
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, widget.skippable ? 24 : 140),
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
        Text(l10n.assessmentOnboardIntro, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
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

class _QuestionView extends StatelessWidget {
  final AssessmentState state;
  final AssessmentController controller;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _QuestionView({
    super.key,
    required this.state,
    required this.controller,
    required this.palette,
    required this.l10n,
  });

  List<String> _questions() => [
        l10n.phq9Q1, l10n.phq9Q2, l10n.phq9Q3, l10n.phq9Q4, l10n.phq9Q5,
        l10n.phq9Q6, l10n.phq9Q7, l10n.phq9Q8, l10n.phq9Q9,
        l10n.gad7Q1, l10n.gad7Q2, l10n.gad7Q3, l10n.gad7Q4, l10n.gad7Q5, l10n.gad7Q6, l10n.gad7Q7,
      ];

  @override
  Widget build(BuildContext context) {
    final questions = _questions();
    final isAnxietySection = state.step >= kPhq9QuestionCount;
    final progress = (state.step + 1) / kAssessmentQuestionCount;
    final answers = [
      l10n.assessmentAnswer0,
      l10n.assessmentAnswer1,
      l10n.assessmentAnswer2,
      l10n.assessmentAnswer3,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SquareIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: state.isFirstStep || state.submitting ? null : controller.goBack,
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
          SectionLabel(isAnxietySection ? l10n.assessmentSectionAnxiety : l10n.assessmentSectionMood,
              color: palette.accent),
          const SizedBox(height: 10),
          Text(questions[state.step], style: AppTypography.title3.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 28),
          for (var i = 0; i < answers.length; i++) ...[
            _AnswerOption(
              label: answers[i],
              selected: state.currentAnswer == i,
              palette: palette,
              onTap: state.submitting ? null : () => controller.selectAndAdvance(i),
            ),
            if (i != answers.length - 1) const SizedBox(height: 10),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(l10n.assessmentSubmitError, style: TextStyle(color: palette.warning)),
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
      default:
        return l10n.assessmentBandSevere;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(l10n.assessmentResultTitle, style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.assessmentResultNote, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  title: l10n.assessmentResultDepression,
                  score: result.phq9Score,
                  max: 27,
                  band: _bandLabel(result.depressionBand),
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreCard(
                  title: l10n.assessmentResultAnxiety,
                  score: result.gad7Score,
                  max: 21,
                  band: _bandLabel(result.anxietyBand),
                  palette: palette,
                ),
              ),
            ],
          ),
          if (result.crisisFlag) ...[
            const SizedBox(height: 20),
            _AssessmentCrisisBanner(palette: palette, l10n: l10n),
          ],
          const SizedBox(height: 28),
          AppPrimaryButton(label: l10n.assessmentContinueCta, onPressed: onContinue),
        ],
      ),
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

  Future<void> _call() async {
    await launchUrl(Uri(scheme: 'tel', path: '112'));
  }

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
                onTap: _call,
                child: Center(
                  child: Text(l10n.chatCallEmergency,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
