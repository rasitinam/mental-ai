import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/user_state.dart';
import 'daily_report_controller.dart';
import 'state_controller.dart';

/// The app's landing screen. Above the daily report sits a live read of
/// where the person is right now: a face, a five-star rating on each axis
/// and a good/bad bar, all driven by an assessment the backend makes from
/// chat, the latest report, the life analysis, journal entries and mood
/// check-ins together — so it moves when their situation moves, instead of
/// being frozen to the last time they touched a slider.
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
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(l10n),
                          style: AppTypography.title1.copyWith(color: palette.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        // Locale-aware on purpose: this used to render
                        // "September Tuesday" for a Turkish user because the
                        // format followed the device, not the app.
                        DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode)
                            .format(DateTime.now()),
                        style: AppTypography.footnote.copyWith(color: palette.textTertiary),
                      ),
                    ],
                  ),
                  _IconButton(
                    icon: Icons.refresh_rounded,
                    palette: palette,
                    onTap: home.refreshing
                        ? null
                        : () => ref.read(stateControllerProvider.notifier).refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MoodHero(data: home, palette: palette, l10n: l10n),
              // Reads the profile itself, so saving a diagnosis rebuilds
              // this strip instead of the whole landing screen.
              _DiagnosesStrip(palette: palette, title: l10n.homeDiagnosesTitle),
              const SizedBox(height: 20),
              if (report.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(report.error!, style: TextStyle(color: palette.warning)),
                ),
              if (report.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: palette.accent)),
                )
              else if (report.report == null && report.error == null)
                _EmptyState(onGenerate: reportController.generateNow, palette: palette, l10n: l10n)
              else if (report.report != null) ...[
                if (report.report!.crisisFlag) ...[
                  _CrisisBanner(palette: palette, l10n: l10n),
                  const SizedBox(height: 14),
                ],
                GlassSurface(
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.homeToday,
                          style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                      const SizedBox(height: 10),
                      Text(report.report!.summary,
                          style: AppTypography.body.copyWith(color: palette.textPrimary)),
                    ],
                  ),
                ),
                if (report.report!.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _RecommendationsCard(
                    items: report.report!.recommendations,
                    palette: palette,
                    title: l10n.homeRecommendations,
                  ),
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

/// Maps a -1..1 valence reading to the face someone sees first.
String _faceFor(double? valence) {
  if (valence == null) return '🙂';
  if (valence >= 0.5) return '😄';
  if (valence >= 0.15) return '😊';
  if (valence > -0.15) return '😐';
  if (valence > -0.5) return '😟';
  return '😢';
}

class _MoodHero extends StatelessWidget {
  final HomeStateData data;
  final AppPalette palette;
  final AppLocalizations l10n;
  const _MoodHero({required this.data, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final state = data.state;

    return GlassSurface(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      child: Column(
        children: [
          Text(_faceFor(state?.valence), style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            state?.headline ?? (data.loading ? l10n.commonLoading : l10n.homeStateNoData),
            textAlign: TextAlign.center,
            style: AppTypography.title2.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            data.refreshing
                ? l10n.homeRefreshing
                : (state?.note ?? l10n.homeStateNoDataNote),
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textTertiary),
          ),
          if (state != null) ...[
            const SizedBox(height: 20),
            _LevelBar(
              label: l10n.homeMoodLabel,
              level: UserState.stars(state.valence),
              palette: palette,
            ),
            const SizedBox(height: 10),
            _LevelBar(
              label: l10n.homeEnergyLabel,
              level: UserState.stars(state.energy),
              palette: palette,
            ),
            const SizedBox(height: 22),
            _GoodBadBar(value: state.valence, palette: palette),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.homeBarBad,
                    style: AppTypography.caption
                        .copyWith(color: palette.textTertiary, letterSpacing: 0.4)),
                Text(l10n.homeBarGood,
                    style: AppTypography.caption
                        .copyWith(color: palette.textTertiary, letterSpacing: 0.4)),
              ],
            ),
            if (state.basis.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.homeBasedOn(state.basis.join(', ')),
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: palette.textTertiary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A labeled 0-5 level as five equal bars, filled up to the level — the
/// same reading as a star row (five is five, half-full is roughly
/// "middling"), just steadier at a glance since every segment is the
/// same shape.
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
            Text(label, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
            Text(
              '$level / 5',
              style: AppTypography.footnote.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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

class _GoodBadBar extends StatelessWidget {
  final double value;
  final AppPalette palette;
  const _GoodBadBar({required this.value, required this.palette});

  @override
  Widget build(BuildContext context) {
    final fraction = ((value.clamp(-1.0, 1.0) + 1) / 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbLeft = fraction * constraints.maxWidth;
        return SizedBox(
          height: 18,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors: [palette.warning, palette.textTertiary, palette.accent],
                  ),
                ),
              ),
              Positioned(
                left: (thumbLeft - 9).clamp(0.0, constraints.maxWidth - 18),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.textPrimary,
                    border: Border.all(color: palette.accent, width: 3),
                    boxShadow: [
                      BoxShadow(color: palette.glassShadow, blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<String> items;
  final AppPalette palette;
  final String title;
  const _RecommendationsCard({
    required this.items,
    required this.palette,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionBadge(icon: Icons.lightbulb_outline_rounded, palette: palette),
              const SizedBox(width: 10),
              Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: i == items.length - 1
                  ? null
                  : BoxDecoration(border: Border(bottom: BorderSide(color: palette.separator))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(items[i],
                        style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resolved.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: palette.accent.withValues(alpha: 0.33)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(resolved[i].emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
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
    return GlassSurface(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 19, color: palette.accent),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTypography.caption
                      .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final AppPalette palette;
  final VoidCallback? onTap;
  const _IconButton({required this.icon, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.accentSoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: palette.accent),
        ),
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final IconData icon;
  final AppPalette palette;
  const _SectionBadge({required this.icon, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(11)),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: palette.accent),
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
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: Icon(Icons.event_note_outlined, size: 28, color: palette.accent),
          ),
          const SizedBox(height: 16),
          Text(l10n.homeNoReport,
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.warningSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border_rounded, size: 18, color: palette.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.homeCrisisWarning,
                style: AppTypography.subheadline.copyWith(color: palette.warning)),
          ),
        ],
      ),
    );
  }
}
