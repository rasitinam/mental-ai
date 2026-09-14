import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../discoveries/data/discoveries_api.dart';
import '../../discoveries/presentation/discoveries_section.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/widgets/hearth_flame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../streak/data/streak_api.dart';
import '../../streak/domain/streak_summary.dart';
import '../domain/user_state.dart';
import 'daily_report_controller.dart';
import 'state_controller.dart';

/// The app's landing screen, in the order the design puts things: where
/// you are right now, how long you've kept it up, what today's note
/// says, and the three places you'd go next.
class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final report = ref.watch(dailyReportControllerProvider);
    final reportController = ref.read(dailyReportControllerProvider.notifier);
    final home = ref.watch(stateControllerProvider);
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          // Pull-to-refresh reassesses rather than re-reads: the whole point
          // is that a conversation from ten minutes ago should change what
          // this screen says.
          onRefresh: () async {
            await Future.wait([
              ref.read(stateControllerProvider.notifier).refresh(),
              reportController.loadLatest(),
            ]);
            ref.invalidate(streakProvider);
            ref.invalidate(discoveriesProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(22, 8, 22, bottomClearance(context)),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(l10n),
                            style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                        const SizedBox(height: 3),
                        Text(
                          // Locale-aware on purpose: this used to render
                          // "September Tuesday" for a Turkish user because the
                          // format followed the device, not the app.
                          DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode)
                              .format(DateTime.now()),
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SquareIconButton(
                    icon: Icons.refresh_rounded,
                    iconColor: palette.accent,
                    onPressed: home.refreshing
                        ? null
                        : () => ref.read(stateControllerProvider.notifier).refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StateCard(data: home, palette: palette, l10n: l10n),
              const SizedBox(height: 16),
              // Carries its own bottom spacing, and takes none at all when
              // there's nothing to show.
              const DiscoveriesStrip(),
              const _StreakCard(),
              const SizedBox(height: 16),
              const _RecapCard(),
              // Reads the profile itself, so saving a diagnosis rebuilds
              // this strip instead of the whole landing screen.
              _DiagnosesStrip(palette: palette, title: l10n.homeDiagnosesTitle),
              const SizedBox(height: 16),
              if (report.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(friendlyErrorMessage(l10n, report.error!),
                      style: TextStyle(color: palette.warning)),
                ),
              if (report.loading)
                const _ReportSkeleton()
              else if (report.report == null && report.error == null)
                _EmptyState(onGenerate: reportController.generateNow, palette: palette, l10n: l10n)
              else if (report.report != null) ...[
                if (report.report!.crisisFlag) ...[
                  _CrisisBanner(palette: palette, l10n: l10n),
                  const SizedBox(height: 16),
                ],
                SectionLabel(l10n.homeToday),
                const SizedBox(height: 8),
                Text(
                  report.report!.summary,
                  style: AppTypography.subheadline
                      .copyWith(color: palette.textPrimary, fontSize: 14.5, height: 1.6),
                ),
                if (report.report!.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SectionLabel(l10n.homeRecommendations),
                  const SizedBox(height: 8),
                  for (final item in report.report!.recommendations)
                    _Bullet(text: item, color: palette.accent, palette: palette),
                ],
                const SizedBox(height: 20),
              ],
              _QuickActions(palette: palette, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 6) return l10n.greetingNight;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingDay;
    return l10n.greetingEvening;
  }
}

/// The face that carries the whole card at a glance. Five steps rather
/// than a continuous curve, because a face people read in half a second
/// should land on a recognizable expression, not a subtly-off one.
String _faceFor(double? valence) {
  if (valence == null) return '🙂';
  if (valence >= 0.5) return '😄';
  if (valence >= 0.15) return '😊';
  if (valence > -0.15) return '😐';
  if (valence > -0.5) return '😟';
  return '😢';
}

class _StateCard extends StatelessWidget {
  final HomeStateData data;
  final AppPalette palette;
  final AppLocalizations l10n;
  const _StateCard({required this.data, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final state = data.state;

    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_faceFor(state?.valence), style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state?.headline ?? (data.loading ? l10n.commonLoading : l10n.homeStateNoData),
                      style: AppTypography.headline.copyWith(color: palette.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.refreshing
                          ? l10n.homeRefreshing
                          : (state?.note ?? l10n.homeStateNoDataNote),
                      style: AppTypography.footnote
                          .copyWith(color: palette.textSecondary, fontSize: 13.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.separator)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LevelBar(
                    label: l10n.homeMoodLabel,
                    level: UserState.stars(state.valence),
                    palette: palette,
                  ),
                  const SizedBox(height: 14),
                  _LevelBar(
                    label: l10n.homeEnergyLabel,
                    level: UserState.stars(state.energy),
                    palette: palette,
                  ),
                  if (state.basis.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.homeBasedOn(state.basis.join(', ')),
                      style: AppTypography.footnote
                          .copyWith(color: palette.textSecondary, fontSize: 12, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A labeled 0-5 level as five equal bars, filled up to the level.
class _LevelBar extends StatelessWidget {
  final String label;
  final int level;
  final AppPalette palette;
  const _LevelBar({required this.label, required this.level, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
            Text(
              '$level / 5',
              style: AppTypography.footnote
                  .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i <= level ? palette.accent : palette.separator,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Days in a row, with the last seven as a sparkline. Reads its own
/// provider so a slow streak request never holds up the state card
/// above it.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final streak = ref.watch(streakProvider).valueOrNull;
    if (streak == null || streak.current == 0) return const SizedBox.shrink();

    return GlassSurface(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              HearthFlame(streak: streak.current, size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(l10n.streakLabel),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${streak.current}',
                        style:
                            AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 20),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.streakDays,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _Sparkline(streak: streak, palette: palette),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final StreakSummary streak;
  final AppPalette palette;
  const _Sparkline({required this.streak, required this.palette});

  @override
  Widget build(BuildContext context) {
    final peak = streak.peak;

    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < streak.lastSeven.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 8,
              // Floored so an empty day still leaves a stub to read the
              // rhythm against, rather than a gap.
              height: 8 + (streak.lastSeven[i] / peak).clamp(0.0, 1.0) * 15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i == streak.lastSeven.length - 1 && streak.lastSeven[i] > 0
                    ? palette.accent
                    : palette.separator,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stands in for today's note and recommendations while the report loads.
class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 90, height: 11),
          SizedBox(height: 10),
          SkeletonBox(height: 13),
          SizedBox(height: 7),
          SkeletonBox(height: 13),
          SizedBox(height: 7),
          SkeletonBox(width: 200, height: 13),
        ],
      ),
    );
  }
}

/// Entry point into the weekly recap (`RecapScreen`, pushed rather than a
/// tab — it's a destination someone visits, not one they live on). Reads
/// its own localizations rather than taking them as a parameter, the same
/// as `_StreakCard`.
class _RecapCard extends StatelessWidget {
  const _RecapCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recap'),
        child: GlassSurface(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.auto_awesome_rounded, size: 18, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.recapEntryTitle,
                        style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(l10n.recapEntrySubtitle,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  final AppPalette palette;
  const _Bullet({required this.text, required this.color, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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
            child: Text(text,
                style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _DiagnosesStrip extends ConsumerWidget {
  final AppPalette palette;
  final String title;
  const _DiagnosesStrip({required this.palette, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slugs = ref.watch(profileControllerProvider.select((s) => s.diagnoses));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    final resolved = <({String emoji, String name})>[];
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (slugs.contains(disorder.slug)) {
          resolved.add((emoji: category.emoji, name: disorder.name));
        }
      }
    }
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resolved.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(resolved[i].emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 7),
                      Text(resolved[i].name,
                          style: AppTypography.footnote.copyWith(color: palette.accent)),
                    ],
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

class _QuickActions extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;
  const _QuickActions({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.emoji_emotions_outlined,
            label: l10n.navMood,
            palette: palette,
            onTap: () => context.go('/mood'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.menu_book_outlined,
            label: l10n.navJournal,
            palette: palette,
            onTap: () => context.go('/journal'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.forum_outlined,
            label: l10n.navChat,
            palette: palette,
            onTap: () => context.go('/chat'),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: palette.accent),
              const SizedBox(height: 10),
              Text(label,
                  style: AppTypography.footnote
                      .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w500)),
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
  final AppLocalizations l10n;
  const _EmptyState({required this.onGenerate, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Icon(Icons.event_note_outlined, size: 22, color: palette.accent),
          ),
          const SizedBox(height: 14),
          Text(l10n.homeNoReport,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 18),
          SizedBox(
            width: 200,
            child: AppPrimaryButton(label: l10n.homeGenerateReport, onPressed: onGenerate),
          ),
        ],
      ),
    );
  }
}

class _CrisisBanner extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;
  const _CrisisBanner({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.warningSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.warning, width: 2),
            ),
            child: Text('!',
                style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: palette.warning)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.homeCrisisWarning,
                style: AppTypography.footnote.copyWith(color: palette.warning)),
          ),
        ],
      ),
    );
  }
}
