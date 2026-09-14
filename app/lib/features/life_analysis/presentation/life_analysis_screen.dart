import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/widgets/mood_heatmap.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../mood_tracking/data/mood_api.dart';
import '../../streak/data/streak_api.dart';
import 'life_analysis_controller.dart';

/// The whole-history view: one narrative over everything the account has
/// recorded, the patterns behind it, and the two lists people actually act
/// on — what to keep doing and what to stop. Regenerated at most weekly
/// (enforced server-side).
class LifeAnalysisScreen extends ConsumerWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(lifeAnalysisControllerProvider);
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;
    final locale = Localizations.localeOf(context).languageCode;
    final analysis = state.analysis;

    final period = analysis == null
        ? null
        : '${DateFormat.MMMd(locale).format(analysis.periodStart)} — '
            '${DateFormat.MMMd(locale).format(analysis.periodEnd)}'
            '${onCooldown ? ' · ${l10n.lifeNextOn(DateFormat.MMMd(locale).format(state.cooldownUntil!))}' : ''}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: controller.loadLatest,
          child: state.loading
              ? ListView(
                  padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
                  children: const [_LifeAnalysisSkeleton()],
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.lifeTitle,
                                  style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                              if (period != null) ...[
                                const SizedBox(height: 4),
                                Text(period,
                                    style: AppTypography.footnote
                                        .copyWith(color: palette.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: onCooldown ? l10n.lifeCooldownTooltip : l10n.lifeRegenerate,
                          child: SquareIconButton(
                            icon: Icons.refresh_rounded,
                            iconColor: palette.accent,
                            onPressed: onCooldown ? null : controller.generateNow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _PeriodStreakCard(),
                    const _MoodHistoryCard(),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(friendlyErrorMessage(l10n, state.error!),
                            style: TextStyle(color: palette.warning)),
                      ),
                    if (analysis == null && state.error == null)
                      _EmptyState(onGenerate: controller.generateNow, palette: palette)
                    else if (analysis != null) ...[
                      SectionLabel(l10n.lifeOverview),
                      const SizedBox(height: 8),
                      Text(
                        analysis.narrative,
                        style: AppTypography.subheadline
                            .copyWith(color: palette.textPrimary, fontSize: 14.5, height: 1.65),
                      ),
                      if (analysis.keyPatterns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _StripeCard(
                          title: l10n.lifePatterns,
                          items: analysis.keyPatterns,
                          color: palette.accent,
                          palette: palette,
                        ),
                      ],
                      if (analysis.doList.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _StripeCard(
                          title: l10n.lifeDoList,
                          items: analysis.doList,
                          color: palette.accentAlt,
                          palette: palette,
                        ),
                      ],
                      if (analysis.dontList.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _StripeCard(
                          title: l10n.lifeDontList,
                          items: analysis.dontList,
                          color: palette.warning,
                          palette: palette,
                        ),
                      ],
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// How much of the last week actually got recorded, as the run of dots
/// the design uses here instead of the home screen's bars — same data,
/// read as "did I show up" rather than "how much did I do".
class _PeriodStreakCard extends ConsumerWidget {
  const _PeriodStreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final streak = ref.watch(streakProvider).valueOrNull;
    if (streak == null || streak.periodActive == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassSurface(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.streakPeriodLabel),
                const SizedBox(height: 2),
                Text(
                  l10n.streakPeriodValue(streak.periodActive, streak.periodDays),
                  style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 20),
                ),
              ],
            ),
            Row(
              children: [
                for (var i = 0; i < streak.lastSeven.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: streak.lastSeven[i] > 0 ? palette.accent : palette.separator,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for the header, streak card and narrative while the first
/// load is in flight.
class _LifeAnalysisSkeleton extends StatelessWidget {
  const _LifeAnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 160, height: 22),
        SizedBox(height: 8),
        SkeletonBox(width: 120, height: 13),
        SizedBox(height: 22),
        SkeletonBox(height: 60, radius: 18),
        SizedBox(height: 22),
        SkeletonBox(width: 90, height: 11),
        SizedBox(height: 10),
        SkeletonBox(height: 13),
        SizedBox(height: 7),
        SkeletonBox(height: 13),
        SizedBox(height: 7),
        SkeletonBox(width: 200, height: 13),
      ],
    );
  }
}

/// The mood heatmap, wrapped the same self-padded way as
/// [_PeriodStreakCard] above it. Reads its own provider (rather than
/// taking history as a parameter) so a slow request never holds up the
/// narrative text above it, and hides itself entirely once there's
/// nothing to shade a grid with.
class _MoodHistoryCard extends ConsumerWidget {
  const _MoodHistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(moodHistoryProvider).valueOrNull;
    if (history == null || history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassSurface(
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.lifeMoodHistoryTitle),
            const SizedBox(height: 14),
            MoodHeatmap(entries: history),
          ],
        ),
      ),
    );
  }
}

/// A card with a colored stripe down its leading edge — the design's way
/// of separating "patterns", "what helps" and "what doesn't" without
/// three competing headline colors. Built as a clipped row rather than a
/// one-sided border, which Flutter won't combine with a corner radius.
class _StripeCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final AppPalette palette;

  const _StripeCard({
    required this.title,
    required this.items,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: palette.glassFill,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 3, child: ColoredBox(color: color)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(title, color: color),
                      const SizedBox(height: 11),
                      for (final item in items)
                        Padding(
                          padding: EdgeInsets.only(bottom: item == items.last ? 0 : 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item,
                                    style: AppTypography.subheadline
                                        .copyWith(color: palette.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  final AppPalette palette;
  const _EmptyState({required this.onGenerate, required this.palette});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Icon(Icons.insights_outlined, size: 22, color: palette.accent),
          ),
          const SizedBox(height: 14),
          Text(l10n.lifeEmpty,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 6),
          Text(
            l10n.lifeEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: AppPrimaryButton(label: l10n.lifeGenerate, onPressed: onGenerate),
          ),
        ],
      ),
    );
  }
}
