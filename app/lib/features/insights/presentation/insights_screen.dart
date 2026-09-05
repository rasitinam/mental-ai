import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';

/// Placeholder for the research-backed insight feed. Will read from the
/// backend's `/insights` endpoint (surfacing `mental_domain::Insight`
/// records distilled from `research-ingest`'s corpus) once that route is
/// wired up server-side.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('İçgörüler')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: GlassSurface(
            radius: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_outlined, size: 30, color: palette.accent),
                const SizedBox(height: 14),
                Text(
                  'Araştırma tabanlı içgörüler burada listelenecek',
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Arka planda çalışan araştırma servisi yeni makaleler '
                  'topladıkça bu ekran güncellenecek.',
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
