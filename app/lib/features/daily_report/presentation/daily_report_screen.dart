import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/settings_jump.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
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
/// thing people come to do. In the day the state and discoveries follow;
/// after 18:00 the check-in becomes the evening one and today's note moves
/// up under it.
class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final reportController = ref.read(dailyReportControllerProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final evening = now.hour >= 18;
    final name = ref.watch(myProfileProvider).valueOrNull?.displayName.trim().split(' ').first ?? '';
    final greeting = _greeting(l10n, now.hour);

    final sections = evening
        ? const <Widget>[_TodayNote(), _MetooCard(), _StateCard(), DiscoveriesStrip()]
        : const <Widget>[_StateCard(), DiscoveriesStrip(), _TodayNote(), _MetooCard()];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.textPrimary,
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
                          DateFormat('EEEE, d MMMM', locale).format(now),
                          style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SupportPill(),
                      const SizedBox(height: 8),
                      PillButton(
                        icon: Icons.settings_outlined,
                        label: AppLocalizations.of(context)!.settingsTitle,
                        onTap: () {
                          ref.read(settingsJumpProvider.notifier).state++;
                          context.go('/settings');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _CheckinTile(evening: evening),
              const SizedBox(height: 18),
              ...sections,
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(AppLocalizations l10n, int hour) {
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

const _dayWords = ['calm', 'hopeful', 'tired', 'tense', 'heavy', 'joyful'];
const _eveningWords = ['calm', 'tired', 'relieved', 'tense'];

/// The check-in, on the landing screen instead of at the bottom of it.
/// Drawn with the light theme in both modes: the tile keeps its color in the
/// dark, so what's on it keeps its ink.
class _CheckinTile extends ConsumerWidget {
  final bool evening;
  const _CheckinTile({required this.evening});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mood = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final done = mood.isOnCooldown;
    final words = evening ? _eveningWords : _dayWords;

    final IconData eyebrowIcon;
    final String eyebrow;
    if (done) {
      eyebrowIcon = Icons.check_circle_rounded;
      eyebrow = l10n.navToday;
    } else if (evening) {
      eyebrowIcon = Icons.nights_stay_outlined;
      eyebrow = l10n.notificationsCheckinTitle;
    } else {
      eyebrowIcon = Icons.wb_twilight_rounded;
      eyebrow = l10n.todayNoCheckinYet;
    }

    return LightSurface(
      child: Builder(
        builder: (context) {
          final palette = AppPalette.of(context);

          return GlassSurface(
            color: evening ? palette.sky : palette.sun,
            radius: 28,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(eyebrowIcon, size: 17, color: palette.textPrimary),
                    const SizedBox(width: 7),
                    Flexible(child: SectionLabel(eyebrow, color: palette.textPrimary)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  done ? l10n.moodDoneToday : (evening ? l10n.notificationsPreviewTitle : l10n.moodHowAreYou),
                  style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 23, height: 1.12),
                ),
                if (done) ...[
                  const SizedBox(height: 10),
                  CountdownText(
                    until: mood.cooldownUntil!,
                    onFinished: () => ref.invalidate(moodControllerProvider),
                    format: (remaining) => l10n.moodNextIn(_formatRemaining(l10n, remaining)),
                    style: AppTypography.subheadline.copyWith(color: palette.textPrimary, fontSize: 15.5),
                  ),
                ] else ...[
                  if (evening) ...[
                    const SizedBox(height: 10),
                    Text(l10n.notificationsPreviewBody,
                        style: AppTypography.subheadline.copyWith(color: palette.textPrimary, fontSize: 15.5)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in words)
                        AppChip(
                          label: moodEmotionLabel(l10n, key),
                          selected: mood.emotions.contains(key),
                          fill: Colors.white.withValues(alpha: 0.55),
                          onTap: () {
                            if (!mood.emotions.contains(key)) controller.toggleEmotion(key);
                            showQuickCheckinSheet(context, ref);
                          },
                        ),
                      AppChip(
                        label: l10n.todayMoreWords(moodEmotions.length - words.length),
                        selected: false,
                        outlined: true,
                        onTap: () => showQuickCheckinSheet(context, ref),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: l10n.todayWriteJournal,
                        icon: Icons.edit_outlined,
                        height: 52,
                        radius: 16,
                        fontSize: 16,
                        onPressed: () => context.go('/journal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlineBlockButton(
                        icon: Icons.mic_none_rounded,
                        label: l10n.todaySpeak,
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
        },
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

/// "Durumun": today's reading, the streak, and keyif/enerji as words.
/// Pull to refresh reassesses it.
class _StateCard extends ConsumerWidget {
  const _StateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final data = ref.watch(stateControllerProvider);
    final state = data.state;
    final streak = ref.watch(streakProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SectionLabel(l10n.todayYourState)),
                if (streak != null && streak.current > 0) ...[
                  Icon(Icons.local_fire_department_rounded, size: 18, color: palette.ember),
                  const SizedBox(width: 5),
                  Text(l10n.todayStreak(streak.current),
                      style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              state?.headline ?? (data.loading ? l10n.commonLoading : l10n.homeStateNoData),
              style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              data.refreshing ? l10n.homeRefreshing : (state?.note ?? l10n.homeStateNoDataNote),
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5),
            ),
            if (state != null) ...[
              const SizedBox(height: 14),
              _Meter(label: l10n.homeMoodLabel, stars: UserState.stars(state.valence)),
              const SizedBox(height: 10),
              _Meter(label: l10n.homeEnergyLabel, stars: UserState.stars(state.energy)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  final String label;
  final int stars;
  const _Meter({required this.label, required this.stars});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: '$label: ${_levelWord(l10n, stars)}',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(label, style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5)),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              _levelWord(l10n, stars),
              textAlign: TextAlign.right,
              style: AppTypography.subheadline.copyWith(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 kişi hikayende kendini buldu" — the author's side of "Bende de oldu",
/// surfaced where they land instead of only inside their stories.
class _MetooCard extends ConsumerWidget {
  const _MetooCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mine = ref.watch(storiesControllerProvider.select((s) => s.mine));
    final withMetoo = mine.where((story) => story.metooCount > 0).toList();
    final total = withMetoo.fold<int>(0, (sum, story) => sum + story.metooCount);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: palette.peach,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/settings/my-stories'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MetooGlyph(size: 22, color: palette.onTint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        withMetoo.length == 1 ? l10n.todayMetooCardOne(total) : l10n.todayMetooCard(total),
                        style: AppTypography.label.copyWith(color: palette.onTint, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(l10n.todayMetooCardAction,
                          style: AppTypography.subheadline.copyWith(color: palette.onTint.withValues(alpha: 0.8), fontSize: 14.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: palette.onTint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's note from the daily report, with its suggestions — or the way to
/// generate one.
class _TodayNote extends ConsumerWidget {
  const _TodayNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final report = ref.watch(dailyReportControllerProvider);
    final controller = ref.read(dailyReportControllerProvider.notifier);

    final Widget body;
    if (report.loading) {
      body = const _ReportSkeleton();
    } else if (report.report == null && report.error != null) {
      body = GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(l10n.homeToday),
            const SizedBox(height: 10),
            Text(friendlyErrorMessage(l10n, report.error!),
                style: AppTypography.subheadline.copyWith(color: palette.warning)),
            const SizedBox(height: 14),
            OutlineBlockButton(label: l10n.commonRetry, onTap: controller.loadLatest),
          ],
        ),
      );
    } else if (report.report == null) {
      body = GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(l10n.homeToday),
            const SizedBox(height: 10),
            Text(l10n.homeNoReport, style: AppTypography.body.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 16),
            AppPrimaryButton(label: l10n.homeGenerateReport, onPressed: controller.generateNow),
          ],
        ),
      );
    } else {
      final today = report.report!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (today.crisisFlag) ...[
            const _CrisisBanner(),
            const SizedBox(height: 14),
          ],
          GlassSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.homeToday),
                const SizedBox(height: 10),
                Text(today.summary, style: AppTypography.body.copyWith(color: palette.textPrimary)),
                if (today.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionLabel(l10n.homeRecommendations),
                  const SizedBox(height: 10),
                  for (final item in today.recommendations) _Bullet(text: item),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 18), child: body);
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
                child: Text(l10n.homeCrisisWarning, style: AppTypography.subheadline.copyWith(color: palette.warning)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
