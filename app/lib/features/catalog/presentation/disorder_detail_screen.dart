import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: explainer.when(
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

    return ListView(
      padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
      children: [
        Row(
          children: [
            SquareIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            if (category != null) ...[
              const SizedBox(width: 14),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    category!.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.footnote
                        .copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(
                explainer.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 19,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(explainer.name,
                  style: AppTypography.title1.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _Section(title: l10n.cardWhatIsIt, body: explainer.whatItIs, palette: palette),
        const SizedBox(height: 18),
        _Section(title: l10n.cardHowDevelops, body: explainer.howItDevelops, palette: palette),
        if (explainer.copingPaths.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ListCard(
            title: l10n.cardWhatHelps,
            items: explainer.copingPaths,
            bulletColor: palette.accent,
            palette: palette,
          ),
        ],
        if (explainer.treatmentPaths.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ListCard(
            title: l10n.cardProfessionalHelp,
            items: explainer.treatmentPaths,
            bulletColor: palette.accentAlt,
            palette: palette,
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            l10n.cardDisclaimer,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// A plain labelled paragraph — the design leaves these uncarded so the
/// two list sections below them are the things that read as boxes.
class _Section extends StatelessWidget {
  final String title;
  final String body;
  final AppPalette palette;
  const _Section({required this.title, required this.body, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: 7),
        Text(body,
            style: AppTypography.subheadline
                .copyWith(color: palette.textPrimary, fontSize: 14.5, height: 1.65)),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color bulletColor;
  final AppPalette palette;

  const _ListCard({
    required this.title,
    required this.items,
    required this.bulletColor,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: item == items.last ? 0 : 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.accent),
            const SizedBox(height: 20),
            Text(l10n.cardPreparing,
                style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
            const SizedBox(height: 8),
            Text(
              l10n.cardPreparingBody,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: palette.textSecondary),
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 28, color: palette.warning),
            const SizedBox(height: 14),
            Text(l10n.cardLoadFailed,
                style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(label: l10n.commonRetry, onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
