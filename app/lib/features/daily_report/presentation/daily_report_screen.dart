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
import '../../../core/widgets/countdown_text.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../discoveries/data/discoveries_api.dart';
import '../../discoveries/presentation/discoveries_section.dart';
import '../../journal/presentation/journal_screen.dart' show journalStartDictationProvider;
import '../../mood_tracking/domain/mood_emotion.dart';
import '../../mood_tracking/presentation/mood_controller.dart';
import '../../mood_tracking/presentation/quick_checkin_sheet.dart';
import '../../profile/data/profile_api.dart';
import '../../stories/presentation/metoo.dart' show MetooGlyph;
import '../../stories/presentation/stories_controller.dart';
import '../../streak/data/streak_api.dart';
import '../domain/user_state.dart';
import 'daily_report_controller.dart';
import 'state_controller.dart';

/// Bugün — where the app opens. The check-in comes first because it's the
/// thing people come to do; then where they are, what the records show,
/// and today's note.
class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final report = ref.watch(dailyReportControllerProvider);
    final reportController = ref.read(dailyReportControllerProvider.notifier);
    final home = ref.watch(stateControllerProvider);
    final palette = AppPalette.of(context);
    final name = ref.watch(myProfileProvider).valueOrNull?.displayName.trim().split(' ').first ?? '';
    final greeting = _greeting(l10n);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            await Future.wait([
              ref.read(stateControllerProvider.notifier).refresh(),
              reportController.loadLatest(),
            ]);
            ref.invalidate(streakProvider);
            ref.invalidate(discoveriesProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(22, 10, 22, bottomClearance(context)),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode)
                              .format(DateTime.now()),
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.isEmpty ? greeting : '$greeting,\n$name',
                          style: AppTypography.largeTitle.copyWith(color: palette.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SupportPill(),
                ],
              ),
              const SizedBox(height: 20),
              const _CheckinTile(),
              const SizedBox(height: 14),
              _StateCard(data: home),
              const SizedBox(height: 14),
              const _MetooCard(),
              const DiscoveriesStrip(),
              if (report.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(friendlyErrorMessage(l10n, report.error!),
                      style: AppTypography.footnote.copyWith(color: palette.warning)),
                ),
              if (report.loading)
                const _ReportSkeleton()
              else if (report.report == null && report.error == null)
                _EmptyState(onGenerate: reportController.generateNow)
              else if (report.report != null) ...[
                if (report.report!.crisisFlag) ...[
                  const _CrisisBanner(),
                  const SizedBox(height: 14),
                ],
                GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(l10n.homeToday),
                      const SizedBox(height: 8),
                      Text(report.report!.summary,
                          style: AppTypography.body.copyWith(color: palette.textPrimary)),
                      if (report.report!.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SectionLabel(l10n.homeRecommendations),
                        const SizedBox(height: 8),
                        for (final item in report.report!.recommendations) _Bullet(text: item),
                      ],
                    ],
                  ),
                ),
              ],
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

String _formatRemaining(AppLocalizations l10n, Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '$hours${l10n.timeUnitHour} $minutes${l10n.timeUnitMinute}';
  return '$minutes${l10n.timeUnitMinute} ${d.inSeconds.remainder(60)}${l10n.timeUnitSecond}';
}

/// The check-in, on the landing screen instead of at the bottom of it.
/// After 18:00 it becomes the evening check-in the reminder points at.
class _CheckinTile extends ConsumerWidget {
  const _CheckinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mood = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final evening = DateTime.now().hour >= 18;
    final done = mood.isOnCooldown;
    final shown = moodEmotions.take(evening ? 3 : 5).toList();
    final chipFill = palette.glassFill.withValues(alpha: 0.6);

    final IconData eyebrowIcon;
    final String eyebrow;
    if (done) {
      eyebrowIcon = Icons.check_circle_rounded;
      eyebrow = l10n.navToday;
    } else if (evening) {
      eyebrowIcon = Icons.nights_stay_rounded;
      eyebrow = l10n.notificationsCheckinTitle;
    } else {
      eyebrowIcon = Icons.wb_twilight_rounded;
      eyebrow = l10n.todayNoCheckinYet;
    }

    return GlassSurface(
      color: evening ? palette.sky : palette.sun,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(eyebrowIcon, size: 18, color: palette.textPrimary),
              const SizedBox(width: 7),
              Flexible(child: SectionLabel(eyebrow, color: palette.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            done
                ? l10n.moodDoneToday
                : (evening ? l10n.notificationsPreviewTitle : l10n.moodHowAreYou),
            style: AppTypography.title3.copyWith(color: palette.textPrimary),
          ),
          if (done) ...[
            const SizedBox(height: 6),
            CountdownText(
              until: mood.cooldownUntil!,
              onFinished: () => ref.invalidate(moodControllerProvider),
              format: (remaining) => l10n.moodNextIn(_formatRemaining(l10n, remaining)),
              style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
            ),
          ] else ...[
            if (evening) ...[
              const SizedBox(height: 6),
              Text(l10n.notificationsPreviewBody,
                  style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emotion in shown)
                  AppChip(
                    label: moodEmotionLabel(l10n, emotion.key),
                    selected: mood.emotions.contains(emotion.key),
                    fill: chipFill,
                    onTap: () {
                      if (!mood.emotions.contains(emotion.key)) controller.toggleEmotion(emotion.key);
                      showQuickCheckinSheet(context, ref);
                    },
                  ),
                AppChip(
                  label: l10n.todayMoreWords(moodEmotions.length - shown.length),
                  selected: false,
                  outlined: true,
                  onTap: () => showQuickCheckinSheet(context, ref),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: l10n.todayWriteJournal,
                  icon: Icons.edit_outlined,
                  onPressed: () => context.go('/journal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineBlockButton(
                  icon: Icons.mic_none_rounded,
                  label: l10n.todaySpeak,
                  height: 56,
                  onTap: () {
                    ref.read(journalStartDictationProvider.notifier).state = true;
                    context.go('/journal');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _levelWord(AppLocalizations l10n, int stars) => switch (stars) {
      1 => l10n.levelVeryLow,
      2 => l10n.levelLow,
      3 => l10n.levelMid,
      4 => l10n.levelHigh,
      _ => l10n.levelVeryHigh,
    };

class _StateCard extends ConsumerWidget {
  final HomeStateData data;
  const _StateCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = data.state;
    final streak = ref.watch(streakProvider).valueOrNull;

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(l10n.todayYourState)),
              if (streak != null && streak.current > 0) ...[
                Icon(Icons.local_fire_department_rounded, size: 19, color: palette.ember),
                const SizedBox(width: 4),
                Text(l10n.todayStreak(streak.current),
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
              IconButton(
                tooltip: l10n.todayRefreshState,
                onPressed: data.refreshing ? null : () => ref.read(stateControllerProvider.notifier).refresh(),
                icon: Icon(Icons.refresh_rounded, color: palette.textSecondary),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state?.headline ?? (data.loading ? l10n.commonLoading : l10n.homeStateNoData),
                  style: AppTypography.headline.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  data.refreshing ? l10n.homeRefreshing : (state?.note ?? l10n.homeStateNoDataNote),
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                ),
                if (state != null) ...[
                  const SizedBox(height: 16),
                  _Meter(label: l10n.homeMoodLabel, stars: UserState.stars(state.valence)),
                  const SizedBox(height: 10),
                  _Meter(label: l10n.homeEnergyLabel, stars: UserState.stars(state.energy)),
                  if (state.basis.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l10n.homeBasedOn(state.basis.join(', ')),
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A 1-5 level as five segments plus the word for it — the number itself
/// isn't something anyone reads anything out of.
class _Meter extends StatelessWidget {
  final String label;
  final int stars;
  const _Meter({required this.label, required this.stars});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
        ),
        Expanded(
          child: Row(
            children: [
              for (var i = 1; i <= 5; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i <= stars ? palette.accent : palette.separator,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            _levelWord(l10n, stars),
            textAlign: TextAlign.right,
            style: AppTypography.footnote.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// "3 kişi hikayelerinde kendini buldu" — the author's side of "Bende de
/// oldu", surfaced where they land instead of only inside their stories.
class _MetooCard extends ConsumerWidget {
  const _MetooCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mine = ref.watch(storiesControllerProvider.select((s) => s.mine));
    final total = mine.fold<int>(0, (sum, story) => sum + story.metooCount);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: palette.peach,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/settings/my-stories'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.glassFill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MetooGlyph(size: 22, color: palette.textPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.todayMetooCard(total),
                          style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(l10n.todayMetooCardAction,
                          style: AppTypography.footnote.copyWith(color: palette.textPrimary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 90, height: 11),
          SizedBox(height: 12),
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

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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
          Expanded(child: Text(text, style: AppTypography.body.copyWith(color: palette.textPrimary))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.homeToday),
          const SizedBox(height: 8),
          Text(l10n.homeNoReport, style: AppTypography.body.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 16),
          AppPrimaryButton(label: l10n.homeGenerateReport, onPressed: onGenerate),
        ],
      ),
    );
  }
}

class _CrisisBanner extends StatelessWidget {
  const _CrisisBanner();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: palette.warningSoft,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSupportSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.support_rounded, size: 22, color: palette.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.homeCrisisWarning,
                    style: AppTypography.subheadline.copyWith(color: palette.warning)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
