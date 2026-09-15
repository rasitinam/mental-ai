import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/widgets/mood_heatmap.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../assessment/data/assessment_api.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../discoveries/data/discoveries_api.dart';
import '../../discoveries/presentation/discoveries_section.dart';
import '../../mood_tracking/data/mood_api.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../session_summary/presentation/session_summary_screen.dart' show sessionBandLabel;
import '../../streak/data/streak_api.dart';
import 'life_analysis_controller.dart';

/// Yolum — everything about the long view in one page: the pre-session
/// summary and weekly recap up top, then what the records show, the
/// screenings, the diagnoses, the life analysis, and the guide.
class LifeAnalysisScreen extends ConsumerWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(lifeAnalysisControllerProvider);
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final analysis = state.analysis;

    final period = analysis == null
        ? null
        : '${DateFormat.MMMd(locale).format(analysis.periodStart)} – '
            '${DateFormat.MMMd(locale).format(analysis.periodEnd)}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            ref.invalidate(discoveriesProvider);
            ref.invalidate(latestAssessmentProvider);
            ref.invalidate(moodHistoryProvider);
            await controller.loadLatest();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(22, 10, 22, bottomClearance(context)),
            children: [
              Text(l10n.navPath, style: AppTypography.title2.copyWith(color: palette.textPrimary)),
              if (period != null) ...[
                const SizedBox(height: 4),
                Text(period, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              ],
              const SizedBox(height: 18),
              const _LeadTiles(),
              const SizedBox(height: 28),
              const DiscoveriesList(),
              const _MoodHistorySection(),
              const _TestsSection(),
              const _DiagnosesSection(),
              SectionHeader(
                title: l10n.lifeTitle,
                action: state.isOnCooldown ? null : l10n.lifeRegenerate,
                onAction: controller.generateNow,
                trailingNote: state.isOnCooldown
                    ? l10n.lifeNextOn(DateFormat.MMMd(locale).format(state.cooldownUntil!))
                    : null,
              ),
              const SizedBox(height: 10),
              if (state.loading)
                const _AnalysisSkeleton()
              else ...[
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(friendlyErrorMessage(l10n, state.error!),
                        style: AppTypography.footnote.copyWith(color: palette.warning)),
                  ),
                if (analysis == null && state.error == null)
                  GlassSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.lifeEmpty, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                        const SizedBox(height: 6),
                        Text(l10n.lifeEmptyBody,
                            style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                        const SizedBox(height: 16),
                        AppPrimaryButton(label: l10n.lifeGenerate, onPressed: controller.generateNow),
                      ],
                    ),
                  )
                else if (analysis != null) ...[
                  GlassSurface(
                    child: Text(analysis.narrative,
                        style: AppTypography.body.copyWith(color: palette.textPrimary)),
                  ),
                  if (analysis.keyPatterns.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ListCard(title: l10n.lifePatterns, items: analysis.keyPatterns, tint: palette.sky),
                  ],
                  if (analysis.doList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ListCard(title: l10n.lifeDoList, items: analysis.doList, tint: palette.mint),
                  ],
                  if (analysis.dontList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ListCard(title: l10n.lifeDontList, items: analysis.dontList, tint: palette.peach),
                  ],
                ],
              ],
              const SizedBox(height: 28),
              ListGroup(
                children: [
                  ListRow(
                    icon: Icons.menu_book_outlined,
                    tint: palette.mint,
                    label: l10n.guideTitle,
                    subtitle: l10n.pathGuideBody,
                    onTap: () => context.go('/insights'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two things people come to Yolum to take away: the page for their
/// therapist and the week at a glance.
class _LeadTiles extends ConsumerWidget {
  const _LeadTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final streak = ref.watch(streakProvider).valueOrNull;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _LeadTile(
              color: palette.accent,
              foreground: palette.onAccent,
              icon: Icons.description_outlined,
              title: l10n.sessionEntryTitle,
              body: l10n.pathSessionBody,
              onTap: () => context.go('/life-analysis/session-summary'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LeadTile(
              color: palette.mint,
              foreground: palette.textPrimary,
              icon: Icons.calendar_view_week_rounded,
              title: l10n.recapTitle,
              body: streak != null && streak.periodActive > 0
                  ? l10n.streakPeriodValue(streak.periodActive, streak.periodDays)
                  : l10n.recapEntrySubtitle,
              onTap: () => context.push('/recap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {
  final Color color;
  final Color foreground;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _LeadTile({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: foreground),
              const Spacer(),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.headline.copyWith(color: foreground, fontSize: 19)),
              const SizedBox(height: 4),
              Text(body, style: AppTypography.footnote.copyWith(color: foreground.withValues(alpha: 0.82))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodHistorySection extends ConsumerWidget {
  const _MoodHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(moodHistoryProvider).valueOrNull;
    if (history == null || history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.lifeMoodHistoryTitle),
          const SizedBox(height: 10),
          GlassSurface(child: MoodHeatmap(entries: history)),
        ],
      ),
    );
  }
}

Color _bandTint(AppPalette palette, String band) => switch (band) {
      'minimal' || 'good' || 'below threshold' || 'high' => palette.mint,
      'mild' || 'low' || 'medium' || 'caution' => palette.sun,
      'moderate' => palette.peach,
      _ => palette.warningSoft,
    };

/// The three screenings people recognize, with their bands in the open —
/// they used to sit three taps deep behind Settings.
class _TestsSection extends ConsumerWidget {
  const _TestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final latest = ref.watch(latestAssessmentProvider);
    final result = latest.valueOrNull;
    final days = result == null ? null : DateTime.now().difference(result.createdAt).inDays;

    Widget band(String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(color: _bandTint(palette, value), borderRadius: BorderRadius.circular(10)),
          child: Text(
            sessionBandLabel(l10n, value),
            style: AppTypography.footnote.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.pathTests,
            trailingNote: days == null ? null : (days <= 0 ? l10n.assessmentLastTakenToday : l10n.assessmentLastTaken(days)),
          ),
          const SizedBox(height: 10),
          if (latest.isLoading)
            const SkeletonBox(height: 200, radius: 24)
          else
            ListGroup(
              children: [
                if (result == null)
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentNeverTaken,
                    subtitle: l10n.assessmentRetakeTitle,
                  )
                else ...[
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultDepression,
                    subtitle: 'PHQ-9',
                    trailing: band(result.depressionBand),
                  ),
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultAnxiety,
                    subtitle: 'GAD-7',
                    trailing: band(result.anxietyBand),
                  ),
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultWellbeing,
                    subtitle: 'WHO-5',
                    trailing: band(result.wellbeingBand),
                  ),
                  ListRow(
                    label: l10n.discoveriesSeeAll,
                    onTap: () => context.go('/life-analysis/assessment'),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: OutlineBlockButton(
                    label: result == null ? l10n.assessmentRetakeCta : l10n.assessmentRetakeAgain,
                    onTap: () => context.go('/life-analysis/assessment/take'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DiagnosesSection extends ConsumerWidget {
  const _DiagnosesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final slugs = ref.watch(profileControllerProvider.select((s) => s.diagnoses));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    final names = <String>[
      for (final category in categories)
        for (final disorder in category.disorders)
          if (slugs.contains(disorder.slug)) disorder.name,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.homeDiagnosesTitle,
            action: names.isEmpty ? null : l10n.storiesEdit,
            onAction: () => context.go('/life-analysis/diagnoses'),
          ),
          const SizedBox(height: 10),
          if (names.isEmpty)
            GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.pathDiagnosesEmpty,
                      style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                  const SizedBox(height: 12),
                  OutlineBlockButton(
                    icon: Icons.add_rounded,
                    label: l10n.pathDiagnosesAdd,
                    onTap: () => context.go('/life-analysis/diagnoses'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in names)
                  Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: palette.glassFill,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(name, style: AppTypography.label.copyWith(color: palette.textPrimary)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A titled list with a colored tag instead of a colored rail — patterns,
/// what helps, what makes things harder.
class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;

  const _ListCard({required this.title, required this.items, required this.tint});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
            child: Text(title,
                style: AppTypography.caption.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: item == items.last ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: palette.textPrimary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Text(item, style: AppTypography.body.copyWith(color: palette.textPrimary))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisSkeleton extends StatelessWidget {
  const _AnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 14),
          SizedBox(height: 8),
          SkeletonBox(height: 14),
          SizedBox(height: 8),
          SkeletonBox(width: 200, height: 14),
        ],
      ),
    );
  }
}
