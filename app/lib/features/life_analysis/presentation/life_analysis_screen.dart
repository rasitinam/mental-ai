import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';

/// Placeholder for the longer-horizon (weekly/monthly) narrative produced
/// by `mental-analysis-engine::generate_life_analysis`. Needs a
/// `/life-analysis/:user_id` backend route before this can call live data.
class LifeAnalysisScreen extends StatelessWidget {
  const LifeAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yaşam Analizi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: GlassSurface(
            radius: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_outlined, size: 30, color: palette.accent),
                const SizedBox(height: 14),
                Text(
                  'Haftalık / aylık yaşam analizi burada görünecek',
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeterli ruh hali ve günlük verisi biriktikçe aktifleşir.',
                  textAlign: TextAlign.center,
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
