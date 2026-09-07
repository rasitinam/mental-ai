import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../data/catalog_api.dart';
import '../domain/disorder_explainer.dart';

/// Reference entry for one condition. The four sections map to what someone
/// actually wants to know in order: what this is, where it comes from, what
/// I can do, and what getting help looks like.
class DisorderDetailScreen extends ConsumerWidget {
  final String slug;
  const DisorderDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final explainer = ref.watch(explainerProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Bilgi Kartı')),
      body: explainer.when(
        loading: () => _LoadingState(palette: palette),
        error: (error, _) => _ErrorState(
          palette: palette,
          onRetry: () => ref.invalidate(explainerProvider(slug)),
        ),
        data: (data) => _Content(explainer: data, palette: palette),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DisorderExplainer explainer;
  final AppPalette palette;
  const _Content({required this.explainer, required this.palette});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      children: [
        Text(explainer.name, style: AppTypography.title1.copyWith(color: palette.textPrimary)),
        const SizedBox(height: 18),
        _Section(
          icon: Icons.help_outline_rounded,
          title: 'Nedir?',
          body: explainer.whatItIs,
          palette: palette,
        ),
        const SizedBox(height: 14),
        _Section(
          icon: Icons.timeline_rounded,
          title: 'Nasıl gelişir?',
          body: explainer.howItDevelops,
          palette: palette,
        ),
        if (explainer.copingPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ListSection(
            icon: Icons.self_improvement_rounded,
            title: 'Günlük hayatta ne yardımcı olur?',
            items: explainer.copingPaths,
            bulletColor: palette.accent,
            palette: palette,
          ),
        ],
        if (explainer.treatmentPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ListSection(
            icon: Icons.medical_services_outlined,
            title: 'Profesyonel destek neleri içerir?',
            items: explainer.treatmentPaths,
            bulletColor: palette.accent,
            palette: palette,
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.warningSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: palette.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu sayfa yalnızca bilgilendirme amaçlıdır ve tanı koymaz. '
                  'Kendinde bu belirtileri görüyorsan bir ruh sağlığı uzmanına danış.',
                  style: AppTypography.footnote.copyWith(color: palette.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final AppPalette palette;
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
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
              Icon(icon, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: AppTypography.body.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color bulletColor;
  final AppPalette palette;
  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.bulletColor,
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
              Icon(icon, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
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

class _LoadingState extends StatelessWidget {
  final AppPalette palette;
  const _LoadingState({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.accent),
            const SizedBox(height: 20),
            Text(
              'Bilgi kartı hazırlanıyor',
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu başlık ilk kez açılıyor; araştırma kaynaklarından derleniyor. '
              'Bir sonraki açılışta anında gelecek.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final AppPalette palette;
  final VoidCallback onRetry;
  const _ErrorState({required this.palette, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 30, color: palette.warning),
            const SizedBox(height: 14),
            Text(
              'Bilgi kartı yüklenemedi',
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(label: 'Tekrar dene', onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
