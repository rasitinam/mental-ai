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
import '../domain/life_analysis.dart';
import 'life_analysis_controller.dart';

/// Yolum — everything about the long view in one page: the pre-session
/// summary and weekly recap up top, then what the records show, the
/// screenings, the diagnoses, the life analysis, and the guide.
class LifeAnalysisScreen extends ConsumerWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final analysis = ref.watch(lifeAnalysisControllerProvider.select((s) => s.analysis));
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.textPrimary,
          onRefresh: () async {
            ref.invalidate(discoveriesProvider);
            ref.invalidate(latestAssessmentProvider);
            ref.invalidate(moodHistoryProvider);
            ref.invalidate(streakProvider);
            await controller.loadLatest();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(22, 10, 22, bottomClearance(context)),
            children: [
              Text(l10n.navPath, style: AppTypography.title2.copyWith(color: palette.textPrimary)),
              if (analysis != null) ...[
                const SizedBox(height: 4),
                Text(_period(analysis, locale),
                    style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5)),
              ],
              const SizedBox(height: 24),
              const _LeadTiles(),
              const SizedBox(height: 30),
              const DiscoveriesList(),
              const _MoodHistorySection(),
              const _TestsSection(),
              const _DiagnosesSection(),
              const _AnalysisSection(),
              OutlinedLinkRow(
                icon: Icons.menu_book_outlined,
                tint: palette.mint,
                label: l10n.guideTitle,
                subtitle: l10n.pathGuideBody,
                onTap: () => context.go('/insights'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _period(LifeAnalysis analysis, String locale) =>
    '${DateFormat.MMMd(locale).format(analysis.periodStart)} – ${DateFormat.MMMd(locale).format(analysis.periodEnd)}';

/// The two things people come to Yolum to take away: the page for their
/// therapist and the week at a glance.
class _LeadTiles extends ConsumerWidget {
  const _LeadTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final streak = ref.watch(streakProvider).valueOrNull;
    final history = ref.watch(moodHistoryProvider).valueOrNull;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekEntries = history?.where((entry) => entry.recordedAt.isAfter(weekAgo)).length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _LeadTile(
              color: palette.accent,
              foreground: palette.onAccent,
              icon: Icons.description_outlined,
              title: l10n.sessionTitle,
              body: l10n.pathSessionBody,
              onTap: () => context.go('/life-analysis/session-summary'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LeadTile(
              color: palette.mint,
              foreground: palette.onTint,
              icon: Icons.calendar_view_week_rounded,
              title: l10n.pathRecapTitle,
              body: weekEntries != null && streak != null
                  ? l10n.pathRecapBody(weekEntries, streak.current)
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
    return Semantics(
      button: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 156),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 26, color: foreground),
                const Spacer(),
                const SizedBox(height: 16),
                Text(title, style: AppTypography.headline.copyWith(color: foreground, fontSize: 19)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.subheadline.copyWith(color: foreground.withValues(alpha: 0.8), fontSize: 14.5)),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.pathMoodHistory, trailingNote: l10n.pathLastFiveWeeks),
          const SizedBox(height: 8),
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

/// The three screenings people recognize, with their bands in the open.
/// Any row opens all seven; the button retakes them.
class _TestsSection extends ConsumerWidget {
  const _TestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final latest = ref.watch(latestAssessmentProvider);
    final result = latest.valueOrNull;
    final days = result == null ? null : DateTime.now().difference(result.createdAt).inDays;

    void openAll() => context.go('/life-analysis/assessment');

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.pathTests,
            trailingNote: days == null ? null : (days <= 0 ? l10n.assessmentLastTakenToday : l10n.pathScreeningAgo(days)),
          ),
          const SizedBox(height: 8),
          if (latest.isLoading)
            const SkeletonBox(height: 220, radius: 24)
          else
            ListGroup(
              children: [
                if (result == null)
                  ListRow(icon: Icons.assignment_outlined, label: l10n.assessmentNeverTaken, subtitle: l10n.assessmentRetakeTitle)
                else ...[
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultDepression,
                    subtitle: 'PHQ-9',
                    trailing: TintTag(
                      label: sessionBandLabel(l10n, result.depressionBand),
                      color: _bandTint(palette, result.depressionBand),
                      height: 30,
                    ),
                    onTap: openAll,
                  ),
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultAnxiety,
                    subtitle: 'GAD-7',
                    trailing: TintTag(
                      label: sessionBandLabel(l10n, result.anxietyBand),
                      color: _bandTint(palette, result.anxietyBand),
                      height: 30,
                    ),
                    onTap: openAll,
                  ),
                  ListRow(
                    icon: Icons.assignment_outlined,
                    label: l10n.assessmentResultWellbeing,
                    subtitle: 'WHO-5',
                    trailing: TintTag(
                      label: sessionBandLabel(l10n, result.wellbeingBand),
                      color: _bandTint(palette, result.wellbeingBand),
                      height: 30,
                    ),
                    onTap: openAll,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: OutlineBlockButton(
                    label: result == null ? l10n.assessmentRetakeCta : l10n.assessmentRetakeAgain,
                    height: 48,
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
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.homeDiagnosesTitle,
            action: names.isEmpty ? null : l10n.storiesEdit,
            onAction: () => context.go('/life-analysis/diagnoses'),
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.pathDiagnosesEmpty, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                  const SizedBox(height: 12),
                  OutlineBlockButton(
                    icon: Icons.add_rounded,
                    label: l10n.pathDiagnosesAdd,
                    height: 48,
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
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(color: palette.glassFill, borderRadius: BorderRadius.circular(100)),
                    child: Text(name, style: AppTypography.label.copyWith(color: palette.textPrimary)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The narrative up front, the rest one tap away — patterns, what helps,
/// what makes things harder, and regenerating when the week is up.
class _AnalysisSection extends ConsumerWidget {
  const _AnalysisSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(lifeAnalysisControllerProvider);
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final analysis = state.analysis;

    final Widget content;
    if (state.loading) {
      content = const GlassSurface(
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
    } else if (analysis == null) {
      content = GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null) ...[
              Text(friendlyErrorMessage(l10n, state.error!), style: AppTypography.footnote.copyWith(color: palette.warning)),
              const SizedBox(height: 10),
            ],
            Text(l10n.lifeEmpty, style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 19)),
            const SizedBox(height: 6),
            Text(l10n.lifeEmptyBody, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 16),
            AppPrimaryButton(label: l10n.lifeGenerate, onPressed: controller.generateNow),
          ],
        ),
      );
    } else {
      content = GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(analysis.narrative,
                maxLines: 5, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(color: palette.textPrimary)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showFullAnalysis(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.pathReadFull,
                  style: AppTypography.label.copyWith(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.lifeTitle, trailingNote: l10n.pathAnalysisNote),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}

void _showFullAnalysis(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context)!;
        final palette = AppPalette.of(context);
        final locale = Localizations.localeOf(context).languageCode;
        final state = ref.watch(lifeAnalysisControllerProvider);
        final analysis = state.analysis;
        if (analysis == null) return const SizedBox.shrink();

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: SheetFrame(
            children: [
              Text(l10n.lifeTitle, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 4),
              Text(_period(analysis, locale), style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              const SizedBox(height: 16),
              Text(analysis.narrative, style: AppTypography.body.copyWith(color: palette.textPrimary)),
              if (analysis.keyPatterns.isNotEmpty) ...[
                const SizedBox(height: 14),
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
              const SizedBox(height: 20),
              if (state.isOnCooldown)
                Text(
                  l10n.lifeNextOn(DateFormat.MMMd(locale).format(state.cooldownUntil!)),
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                )
              else
                AppPrimaryButton(
                  label: l10n.lifeRegenerate,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(lifeAnalysisControllerProvider.notifier).generateNow();
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color tint;

  const _ListCard({required this.title, required this.items, required this.tint});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      color: palette.canvasTop,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintTag(label: title, color: tint),
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
