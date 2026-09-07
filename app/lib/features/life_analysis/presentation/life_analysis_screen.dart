import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'life_analysis_controller.dart';

/// The whole-history view: one narrative over everything the account has
/// recorded, the patterns behind it, and the two lists people actually act
/// on — what to keep doing and what to stop. Regenerated at most weekly
/// (enforced server-side).
class LifeAnalysisScreen extends ConsumerWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeAnalysisControllerProvider);
    final controller = ref.read(lifeAnalysisControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yaşam Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: (state.loading || onCooldown) ? null : controller.generateNow,
            tooltip: onCooldown ? 'Haftada bir yenilenebilir' : 'Yeniden analiz et',
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
                    _EmptyState(onGenerate: controller.generateNow, palette: palette)
                  else if (state.analysis != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${DateFormat.yMMMd().format(state.analysis!.periodStart)} — '
                            '${DateFormat.yMMMd().format(state.analysis!.periodEnd)}',
                            style: AppTypography.footnote.copyWith(color: palette.textTertiary),
                          ),
                        ),
                        if (onCooldown)
                          Text(
                            'Sonraki: ${DateFormat.yMMMd().format(state.cooldownUntil!)}',
                            style: AppTypography.caption.copyWith(color: palette.textTertiary),
                          ),
                      ],
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
                      _BulletCard(
                        icon: Icons.pattern_rounded,
                        title: 'Öne çıkan örüntüler',
                        items: state.analysis!.keyPatterns,
                        bulletColor: palette.accent,
                        titleColor: palette.textPrimary,
                        palette: palette,
                      ),
                    ],
                    if (state.analysis!.doList.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _BulletCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Yapman iyi gelenler',
                        items: state.analysis!.doList,
                        bulletColor: palette.accent,
                        titleColor: palette.textPrimary,
                        palette: palette,
                      ),
                    ],
                    if (state.analysis!.dontList.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _BulletCard(
                        icon: Icons.do_not_disturb_on_outlined,
                        title: 'Sana zorluk çıkaranlar',
                        items: state.analysis!.dontList,
                        bulletColor: palette.warning,
                        titleColor: palette.textPrimary,
                        palette: palette,
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color bulletColor;
  final Color titleColor;
  final AppPalette palette;

  const _BulletCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.bulletColor,
    required this.titleColor,
    required this.palette,
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
              Icon(icon, size: 18, color: bulletColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTypography.headline.copyWith(color: titleColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item,
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
            'Tüm ruh hali, günlük, sohbet ve rapor geçmişine bakarak bir analiz oluşturulur. '
            'Haftada bir yenilenebilir.',
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
