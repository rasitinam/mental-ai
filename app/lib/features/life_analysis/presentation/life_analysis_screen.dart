import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'life_analysis_controller.dart';

class LifeAnalysisScreen extends ConsumerWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeAnalysisControllerProvider);
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yaşam Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.loading ? null : controller.generateNow,
            tooltip: 'Son 30 günü yeniden analiz et',
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
                  if (state.analysis == null && state.error == null)
                    _EmptyState(onGenerate: controller.generateNow, palette: palette),
                  if (state.analysis != null) ...[
                    Text(
                      '${DateFormat.yMMMd().format(state.analysis!.periodStart)} — '
                      '${DateFormat.yMMMd().format(state.analysis!.periodEnd)}',
                      style: AppTypography.footnote.copyWith(color: palette.textTertiary),
                    ),
                    const SizedBox(height: 14),
                    GlassSurface(
                      radius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights_outlined, size: 18, color: palette.accent),
                              const SizedBox(width: 8),
                              Text('Genel görünüm',
                                  style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.analysis!.narrative,
                            style: AppTypography.body.copyWith(color: palette.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    if (state.analysis!.keyPatterns.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassSurface(
                        radius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pattern_rounded, size: 18, color: palette.accent),
                                const SizedBox(width: 8),
                                Text('Öne çıkan örüntüler',
                                    style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (final pattern in state.analysis!.keyPatterns)
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
                                      child: Text(pattern,
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
            child: Icon(Icons.insights_outlined, size: 28, color: palette.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bir yaşam analizin yok.',
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Son 30 günün ruh hali ve günlük verilerine bakarak bir analiz oluşturabilirsin.',
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textTertiary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: AppPrimaryButton(label: 'Analiz oluştur', onPressed: onGenerate),
          ),
        ],
      ),
    );
  }
}
