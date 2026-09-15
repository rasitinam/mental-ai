import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/assessment_api.dart';
import '../domain/assessment_result.dart';
import '../domain/instruments.dart' show kAssessmentQuestionCount;

/// The Settings-side entry point for the PHQ-9 + GAD-7 screening: shows
/// the latest reading, if any, and a button that pushes the same
/// [AssessmentScreen] the onboarding flow uses, in its non-skippable form.
class AssessmentSummaryScreen extends ConsumerWidget {
  const AssessmentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final latest = ref.watch(latestAssessmentProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Inside the shell: clear the floating tab bar (see `bottomClearance`).
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.assessmentRetakeTitle,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
              const SizedBox(height: 18),
              Text(l10n.assessmentRetakeIntro(kAssessmentQuestionCount),
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
              const SizedBox(height: 22),
              latest.when(
                loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                error: (_, _) => const SizedBox.shrink(),
                data: (result) => result == null
                    ? Text(l10n.assessmentNeverTaken,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary))
                    : _LatestSummary(result: result, palette: palette, l10n: l10n),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: latest.valueOrNull == null ? l10n.assessmentRetakeCta : l10n.assessmentRetakeAgain,
                onPressed: () => context.go('/life-analysis/assessment/take'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestSummary extends StatelessWidget {
  final AssessmentResult result;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _LatestSummary({required this.result, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(result.createdAt).inDays;

    return GlassSurface(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(days <= 0 ? l10n.assessmentLastTakenToday : l10n.assessmentLastTaken(days),
              style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _MiniScore(label: l10n.assessmentResultDepression, score: result.phq9Score, palette: palette),
              _MiniScore(label: l10n.assessmentResultAnxiety, score: result.gad7Score, palette: palette),
              _MiniScore(label: l10n.assessmentResultWellbeing, score: result.who5Score, palette: palette),
              _MiniScore(label: l10n.assessmentResultSomatic, score: result.phq15Score, palette: palette),
              _MiniScore(label: l10n.assessmentResultPtsd, score: result.ptsd5Score, palette: palette),
              _MiniScore(label: l10n.assessmentResultAlcohol, score: result.auditcScore, palette: palette),
              _MiniScore(label: l10n.assessmentResultSubstance, score: result.cageaidScore, palette: palette),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final int score;
  final AppPalette palette;

  const _MiniScore({required this.label, required this.score, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
        const SizedBox(height: 4),
        Text('$score', style: AppTypography.headline.copyWith(color: palette.textPrimary)),
      ],
    );
  }
}
