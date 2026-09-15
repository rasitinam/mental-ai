import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../data/discoveries_api.dart';

/// Tag color and label per kind, shared by the strip and the list so a
/// "lifts" card looks the same wherever it shows up.
({Color tint, String label}) _kindStyle(AppPalette palette, AppLocalizations l10n, DiscoveryKind kind) =>
    switch (kind) {
      DiscoveryKind.lifts => (tint: palette.mint, label: l10n.discoveriesKindLifts),
      DiscoveryKind.drains => (tint: palette.peach, label: l10n.discoveriesKindDrains),
      DiscoveryKind.rhythm => (tint: palette.sky, label: l10n.discoveriesKindRhythm),
    };

/// The sentence a card shows: the observation itself, or its title when a
/// card came back without one.
String _sentence(Discovery discovery) => discovery.body.trim().isNotEmpty ? discovery.body : discovery.title;

/// Bugün's version: a sideways row of cards, each wide enough that the
/// next one peeks in from the edge. Takes no room when there's nothing.
class DiscoveriesStrip extends ConsumerWidget {
  const DiscoveriesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final result = ref.watch(discoveriesProvider);

    return result.when(
      // A secondary section failing shouldn't put an error on the landing
      // screen; Yolum's list is where a failure is shown.
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: SkeletonBox(height: 150, radius: 22),
      ),
      data: (data) {
        if (data.locked) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _LockedCard(result: data),
          );
        }
        if (data.cards.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.discoveriesTitle,
                action: l10n.discoveriesSeeAll,
                onAction: () => context.go('/life-analysis'),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: data.cards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => SizedBox(
                    width: data.cards.length == 1 ? MediaQuery.sizeOf(context).width - 44 : 252,
                    child: _DiscoveryCard(discovery: data.cards[i], compact: true),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Yolum's version: every card in full, plus the locked, empty and error
/// states the strip deliberately doesn't show.
class DiscoveriesList extends ConsumerWidget {
  const DiscoveriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final result = ref.watch(discoveriesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.discoveriesTitle),
          const SizedBox(height: 8),
          result.when(
            loading: () => const Column(
              children: [
                SkeletonBox(height: 96, radius: 24),
                SizedBox(height: 8),
                SkeletonBox(height: 96, radius: 24),
              ],
            ),
            error: (_, _) => GlassSurface(
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.discoveriesError,
                        style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(discoveriesProvider),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
            data: (data) {
              if (data.locked) return _LockedCard(result: data);
              if (data.cards.isEmpty) {
                return GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.discoveriesEmptyTitle,
                          style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(l10n.discoveriesEmptyBody,
                          style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final card in data.cards) ...[
                    _DiscoveryCard(discovery: card, compact: false),
                    const SizedBox(height: 8),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(l10n.discoveriesFootnote,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final Discovery discovery;

  /// The strip's fixed-height card clips the sentence and opens the full
  /// card on tap; the list shows everything inline.
  final bool compact;

  const _DiscoveryCard({required this.discovery, required this.compact});

  void _openFull(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = AppPalette.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext)!;
        final style = _kindStyle(palette, l10n, discovery.kind);
        return SheetFrame(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintTag(label: style.label, color: style.tint),
            const SizedBox(height: 14),
            if (discovery.title.trim().isNotEmpty) ...[
              Text(discovery.title, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 8),
            ],
            Text(discovery.body, style: AppTypography.body.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 18),
            Text(l10n.discoveriesFootnote, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final style = _kindStyle(palette, l10n, discovery.kind);

    return Material(
      color: palette.glassFill,
      borderRadius: BorderRadius.circular(compact ? 22 : 24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: compact ? () => _openFull(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TintTag(label: style.label, color: style.tint),
              SizedBox(height: compact ? 9 : 8),
              if (compact)
                Expanded(
                  child: Text(
                    _sentence(discovery),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(color: palette.textPrimary, height: 1.5),
                  ),
                )
              else
                Text(_sentence(discovery), style: AppTypography.body.copyWith(color: palette.textPrimary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Not enough days yet" — framed as progress: one segment per day needed.
class _LockedCard extends StatelessWidget {
  final DiscoveriesResult result;

  const _LockedCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final needed = result.daysNeeded <= 0 ? 7 : result.daysNeeded;
    final logged = result.daysLogged.clamp(0, needed);

    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.discoveriesLockedTitle,
              style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(l10n.discoveriesLockedBody,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < needed; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: i < logged ? palette.accent : palette.separator,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.discoveriesLockedProgress(logged, needed),
                style: AppTypography.footnote.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
