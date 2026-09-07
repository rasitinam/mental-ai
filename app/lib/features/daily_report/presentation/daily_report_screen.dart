import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../mood_tracking/data/mood_api.dart';
import '../../mood_tracking/domain/mood_entry.dart';
import '../../profile/presentation/profile_controller.dart';
import 'daily_report_controller.dart';

/// The app's landing screen. Above the existing daily-report content sits a
/// quick "how are you right now" read: the latest mood check-in as a face
/// and a good/bad bar, the trend note the backend already computes
/// (comparing today against the person's own history), and the diagnoses
/// they've told the app about — so the most personal context is visible
/// before anyone scrolls.
class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyReportControllerProvider);
    final controller = ref.read(dailyReportControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final latestMood = ref.watch(latestMoodProvider);
    final diagnoses = ref.watch(profileControllerProvider).diagnoses;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            ref.invalidate(latestMoodProvider);
            await controller.loadLatest();
          },
          child: state.loading
              ? Center(child: CircularProgressIndicator(color: palette.accent))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting(), style: AppTypography.title1.copyWith(color: palette.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMMM EEEE').format(DateTime.now()),
                              style: AppTypography.footnote.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        ),
                        _IconButton(
                          icon: Icons.refresh_rounded,
                          palette: palette,
                          onTap: state.loading ? null : controller.generateNow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _MoodHero(mood: latestMood.valueOrNull, trendNote: state.report?.moodTrendNote, palette: palette),
                    if (diagnoses.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _DiagnosesStrip(slugs: diagnoses, categories: categories, palette: palette),
                    ],
                    const SizedBox(height: 20),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(state.error!, style: TextStyle(color: palette.warning)),
                      ),
                    if (state.report == null && state.error == null)
                      _EmptyState(onGenerate: controller.generateNow, palette: palette),
                    if (state.report != null) ...[
                      if (state.report!.crisisFlag) ...[
                        _CrisisBanner(palette: palette),
                        const SizedBox(height: 14),
                      ],
                      GlassSurface(
                        radius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bugün', style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                            const SizedBox(height: 10),
                            Text(
                              state.report!.summary,
                              style: AppTypography.body.copyWith(color: palette.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (state.report!.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        GlassSurface(
                          radius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _SectionBadge(icon: Icons.lightbulb_outline_rounded, palette: palette),
                                  const SizedBox(width: 10),
                                  Text('Öneriler',
                                      style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              for (var i = 0; i < state.report!.recommendations.length; i++)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: i == state.report!.recommendations.length - 1
                                      ? null
                                      : BoxDecoration(
                                          border: Border(bottom: BorderSide(color: palette.separator))),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 7),
                                        width: 6,
                                        height: 6,
                                        decoration:
                                            BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(state.report!.recommendations[i],
                                            style: AppTypography.subheadline
                                                .copyWith(color: palette.textPrimary)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                    _QuickActions(palette: palette),
                  ],
                ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }
}

/// Maps a -1..1 valence reading to the face and words someone sees first.
({String emoji, String label}) _moodPresentation(double? valence) {
  if (valence == null) return (emoji: '🙂', label: 'Henüz bir kayıt yok');
  if (valence >= 0.5) return (emoji: '😄', label: 'Harika gidiyorsun');
  if (valence >= 0.15) return (emoji: '😊', label: 'İyi görünüyorsun');
  if (valence > -0.15) return (emoji: '😐', label: 'Dengeli bir haldesin');
  if (valence > -0.5) return (emoji: '😟', label: 'Biraz zorlanıyor olabilirsin');
  return (emoji: '😢', label: 'Zor bir dönemden geçiyorsun');
}

class _MoodHero extends StatelessWidget {
  final MoodEntry? mood;
  final String? trendNote;
  final AppPalette palette;
  const _MoodHero({required this.mood, required this.trendNote, required this.palette});

  @override
  Widget build(BuildContext context) {
    final presentation = _moodPresentation(mood?.valence);
    final fraction = mood == null ? null : ((mood!.valence + 1) / 2).clamp(0.0, 1.0);

    return GlassSurface(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      child: Column(
        children: [
          Text(presentation.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            presentation.label,
            style: AppTypography.title2.copyWith(color: palette.textPrimary),
          ),
          if (trendNote != null) ...[
            const SizedBox(height: 5),
            Text(
              trendNote!,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: palette.textTertiary),
            ),
          ],
          if (fraction != null) ...[
            const SizedBox(height: 22),
            LayoutBuilder(
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
                          gradient: LinearGradient(colors: [
                            palette.warning,
                            palette.textTertiary,
                            palette.accent,
                          ]),
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
                            boxShadow: [BoxShadow(color: palette.glassShadow, blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KÖTÜ',
                    style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.4)),
                Text('İYİ',
                    style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.4)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosesStrip extends StatelessWidget {
  final Set<String> slugs;
  final List<DisorderCategory> categories;
  final AppPalette palette;
  const _DiagnosesStrip({required this.slugs, required this.categories, required this.palette});

  @override
  Widget build(BuildContext context) {
    final resolved = <({String emoji, String name})>[];
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (slugs.contains(disorder.slug)) {
          resolved.add((emoji: category.emoji, name: disorder.name));
        }
      }
    }
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TANILARIM',
          style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final d in resolved)
                Padding(
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
                        Text(d.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(d.name, style: AppTypography.footnote.copyWith(color: palette.accent)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppPalette palette;
  const _QuickActions({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.emoji_emotions_outlined,
            label: 'Ruh Hali',
            palette: palette,
            onTap: () => context.go('/mood'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.menu_book_outlined,
            label: 'Günlük',
            palette: palette,
            onTap: () => context.go('/journal'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.forum_outlined,
            label: 'Sohbet',
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
  const _QuickAction({required this.icon, required this.label, required this.palette, required this.onTap});

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
                  style:
                      AppTypography.caption.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
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
  const _EmptyState({required this.onGenerate, required this.palette});

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
          Text(
            'Henüz bugüne ait bir raporun yok.',
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: AppPrimaryButton(label: 'Rapor oluştur', onPressed: onGenerate),
          ),
        ],
      ),
    );
  }
}

class _CrisisBanner extends StatelessWidget {
  final AppPalette palette;
  const _CrisisBanner({required this.palette});

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
            child: Text(
              'Son günlük kayıtlarında zorlu ifadeler fark ettik. Acil durumdaysan '
              '112\'yi ara; konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.',
              style: AppTypography.subheadline.copyWith(color: palette.warning),
            ),
          ),
        ],
      ),
    );
  }
}
