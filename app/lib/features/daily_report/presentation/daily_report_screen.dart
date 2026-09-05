import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import 'daily_report_controller.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyReportControllerProvider);
    final controller = ref.read(dailyReportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loading ? null : controller.generateNow,
            tooltip: 'Bugünün raporunu yeniden oluştur',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadLatest,
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (state.error != null)
                    Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (state.report == null && state.error == null)
                    _EmptyState(onGenerate: controller.generateNow),
                  if (state.report != null) ...[
                    Text(
                      DateFormat.yMMMMd().add_Hm().format(state.report!.generatedAt),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 12),
                    if (state.report!.crisisFlag) const _CrisisBanner(),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(state.report!.summary, style: const TextStyle(height: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Ruh hali eğilimi', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(state.report!.moodTrendNote),
                    if (state.report!.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Öneriler', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...state.report!.recommendations.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• $r'),
                          )),
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
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.today_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('Henüz bugüne ait bir raporun yok.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onGenerate, child: const Text('Rapor oluştur')),
        ],
      ),
    );
  }
}

class _CrisisBanner extends StatelessWidget {
  const _CrisisBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Son günlük kayıtlarında zorlu ifadeler fark ettik. Acil durumdaysan 112\'yi ara; '
        'konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.',
        style: TextStyle(color: AppColors.warning),
      ),
    );
  }
}
