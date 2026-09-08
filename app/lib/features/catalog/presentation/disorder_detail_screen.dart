import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_api.dart';
import '../domain/disorder_category.dart';
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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.cardTitle)),
      body: explainer.when(
        loading: () => _LoadingState(palette: palette),
        error: (error, _) => _ErrorState(
          palette: palette,
          onRetry: () => ref.invalidate(explainerProvider(slug)),
        ),
        data: (data) {
          final category = categories.where((c) => c.slug == data.category).firstOrNull;
          return _Content(explainer: data, category: category, palette: palette);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DisorderExplainer explainer;
  final DisorderCategory? category;
  final AppPalette palette;
  const _Content({required this.explainer, required this.category, required this.palette});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emoji = category?.emoji ?? '🧠';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      children: [
        if (category != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(100)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category!.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 7),
                Text(
                  category!.name.toUpperCase(),
                  style: AppTypography.caption.copyWith(color: palette.accent, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(explainer.name, style: AppTypography.title1.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _Section(
          icon: Icons.help_outline_rounded,
          title: l10n.cardWhatIsIt,
          body: explainer.whatItIs,
          palette: palette,
        ),
        const SizedBox(height: 14),
        _Section(
          icon: Icons.timeline_rounded,
          title: l10n.cardHowDevelops,
          body: explainer.howItDevelops,
          palette: palette,
        ),
        if (explainer.copingPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ListSection(
            icon: Icons.self_improvement_rounded,
            title: l10n.cardWhatHelps,
            items: explainer.copingPaths,
            palette: palette,
          ),
        ],
        if (explainer.treatmentPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ListSection(
            icon: Icons.medical_services_outlined,
            title: l10n.cardProfessionalHelp,
            items: explainer.treatmentPaths,
            palette: palette,
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.warningSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.info_outline_rounded, size: 14, color: palette.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.cardDisclaimer,
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

/// Small circular icon badge used atop every section card — the visual
/// anchor that lets someone scan the page by icon before reading titles.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final AppPalette palette;
  const _IconBadge({required this.icon, required this.palette});

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
              _IconBadge(icon: icon, palette: palette),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
  final AppPalette palette;
  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
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
              _IconBadge(icon: icon, palette: palette),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
              ),
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
              AppLocalizations.of(context)!.cardPreparing,
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.cardPreparingBody,
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
              AppLocalizations.of(context)!.cardLoadFailed,
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: AppLocalizations.of(context)!.commonRetry,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
