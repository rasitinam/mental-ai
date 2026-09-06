import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../domain/insight.dart';
import 'insights_controller.dart';

/// Research-backed insight feed — reads whatever the background research
/// service (`apps/server/src/scheduler.rs`) has synthesized so far from
/// newly-ingested PTSD/bipolar/anxiety/depression/recovery literature. A
/// fresh install won't have anything until the first ingest cycle
/// (running immediately on server startup, then every few hours) finds
/// and summarizes new articles.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('İçgörüler')),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: controller.load,
        child: state.loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : state.error != null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                    children: [
                      const SizedBox(height: 48),
                      Text(state.error!, style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                    ],
                  )
                : state.insights.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                        children: [
                          const SizedBox(height: 32),
                          _EmptyState(
                            palette: palette,
                            synthesizing: state.synthesizing,
                            onSynthesizeNow: controller.synthesizeNow,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                        itemCount: state.insights.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _InsightCard(insight: state.insights[index]),
                        ),
                      ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(insight.title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.body, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          if (insight.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in insight.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(tag, style: AppTypography.caption.copyWith(color: palette.accent)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            DateFormat.yMMMd().format(insight.createdAt),
            style: AppTypography.caption.copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppPalette palette;
  final bool synthesizing;
  final VoidCallback onSynthesizeNow;
  const _EmptyState({required this.palette, required this.synthesizing, required this.onSynthesizeNow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GlassSurface(
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 30, color: palette.accent),
            const SizedBox(height: 14),
            Text(
              'Henüz bir içgörü yok',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Arka planda çalışan araştırma servisi yeni makaleler '
              'topladıkça bu ekran güncellenecek. Beklemek istemezsen '
              'zaten toplanmış makalelerden şimdi bir içgörü çıkarabilirsin.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: 'Şimdi oluştur',
                loading: synthesizing,
                onPressed: onSynthesizeNow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
