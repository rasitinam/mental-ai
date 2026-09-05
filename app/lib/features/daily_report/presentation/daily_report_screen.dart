import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'daily_report_controller.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyReportControllerProvider);
    final controller = ref.read(dailyReportControllerProvider.notifier);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.loading ? null : controller.generateNow,
            tooltip: 'Bugünün raporunu yeniden oluştur',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: controller.loadLatest,
        child: state.loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(state.error!, style: TextStyle(color: palette.warning)),
                    ),
                  if (state.report == null && state.error == null)
                    _EmptyState(onGenerate: controller.generateNow, palette: palette),
                  if (state.report != null) ...[
                    Text(
                      DateFormat.yMMMMd().add_Hm().format(state.report!.generatedAt),
                      style: AppTypography.footnote.copyWith(color: palette.textTertiary),
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    GlassSurface(
                      radius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.show_chart_rounded, size: 18, color: palette.accent),
                              const SizedBox(width: 8),
                              Text('Ruh hali eğilimi',
                                  style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.report!.moodTrendNote,
                            style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
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
                                Icon(Icons.lightbulb_outline_rounded, size: 18, color: palette.accent),
                                const SizedBox(width: 8),
                                Text('Öneriler',
                                    style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (final r in state.report!.recommendations)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 7),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(r,
                                          style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 48),
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
