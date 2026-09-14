import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../data/discoveries_api.dart';

/// Colors and label per kind, shared by the strip and the list so a
/// "lifts" card looks the same wherever it shows up.
({Color tint, Color soft, String label}) _kindStyle(
  AppPalette palette,
  AppLocalizations l10n,
  DiscoveryKind kind,
) =>
    switch (kind) {
      DiscoveryKind.lifts => (tint: palette.accent, soft: palette.accentSoft, label: l10n.discoveriesKindLifts),
      DiscoveryKind.drains => (tint: palette.warning, soft: palette.warningSoft, label: l10n.discoveriesKindDrains),
      DiscoveryKind.rhythm => (tint: palette.accentAlt, soft: palette.surfaceMuted, label: l10n.discoveriesKindRhythm),
    };

/// The home screen's version: a header and a sideways row of short cards,
/// each wide enough that the next one peeks in from the edge — the only
/// hint a horizontal list needs. Takes no room at all when there is
/// nothing to show, so the home screen never carries an empty section.
class DiscoveriesStrip extends ConsumerWidget {
  const DiscoveriesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final result = ref.watch(discoveriesProvider);

    return result.when(
      // A secondary section failing shouldn't put an error on the landing
      // screen; the life screen's list is where a failure is shown.
      error: (_, _) => const SizedBox.shrink(),
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.discoveriesTitle),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 128, radius: 18)),
                SizedBox(width: 10),
                SizedBox(width: 60, child: SkeletonBox(height: 128, radius: 18)),
              ],
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.locked) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _LockedCard(result: data, palette: palette, l10n: l10n),
          );
        }
        if (data.cards.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SectionLabel(l10n.discoveriesTitle)),
                  InkWell(
                    onTap: () => context.go('/life-analysis'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        l10n.discoveriesSeeAll,
                        style: AppTypography.caption.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = data.cards.length == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth * 0.8).clamp(220.0, 320.0);
                  return SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: data.cards.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => SizedBox(
                        width: cardWidth,
                        child: _DiscoveryCard(discovery: data.cards[i], compact: true),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The life screen's version: every card in full, plus the locked, empty
/// and error states the home strip deliberately doesn't show.
class DiscoveriesList extends ConsumerWidget {
  const DiscoveriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final result = ref.watch(discoveriesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.discoveriesTitle),
          const SizedBox(height: 10),
          result.when(
            loading: () => const Column(
              children: [
                SkeletonBox(height: 96, radius: 18),
                SizedBox(height: 10),
                SkeletonBox(height: 96, radius: 18),
              ],
            ),
            error: (_, _) => GlassSurface(
              radius: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.discoveriesError,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(discoveriesProvider),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
            data: (data) {
              if (data.locked) return _LockedCard(result: data, palette: palette, l10n: l10n);
              if (data.cards.isEmpty) {
                return GlassSurface(
                  radius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.discoveriesEmptyTitle,
                          style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l10n.discoveriesEmptyBody,
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5)),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final card in data.cards) ...[
                    _DiscoveryCard(discovery: card, compact: false),
                    if (card != data.cards.last) const SizedBox(height: 10),
                  ],
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

  /// The home strip's fixed-height card clips the body to a few lines and
  /// opens the full text on tap; the list shows everything inline.
  final bool compact;

  const _DiscoveryCard({required this.discovery, required this.compact});

  void _openFull(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = AppPalette.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext)!;
        final style = _kindStyle(palette, l10n, discovery.kind);
        return Container(
          decoration: BoxDecoration(
            color: palette.canvasTop,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 14, 24, 28 + MediaQuery.paddingOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: palette.separator, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 22),
              _KindHeader(discovery: discovery, style: style, big: true),
              const SizedBox(height: 16),
              Text(discovery.title, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 8),
              Text(discovery.body,
                  style: AppTypography.body.copyWith(color: palette.textSecondary, height: 1.6)),
              const SizedBox(height: 18),
              Text(l10n.discoveriesFootnote,
                  style: AppTypography.caption.copyWith(color: palette.textTertiary, height: 1.5)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final style = _kindStyle(palette, l10n, discovery.kind);

    return GlassSurface(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: compact ? () => _openFull(context) : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _KindHeader(discovery: discovery, style: style, big: false),
              const SizedBox(height: 10),
              Text(
                discovery.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              if (compact)
                Expanded(
                  child: Text(
                    discovery.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.45),
                  ),
                )
              else
                Text(
                  discovery.body,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindHeader extends StatelessWidget {
  final Discovery discovery;
  final ({Color tint, Color soft, String label}) style;
  final bool big;

  const _KindHeader({required this.discovery, required this.style, required this.big});

  @override
  Widget build(BuildContext context) {
    final size = big ? 44.0 : 30.0;
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: style.soft, shape: BoxShape.circle),
          child: Text(discovery.emoji, style: TextStyle(fontSize: big ? 22 : 15)),
        ),
        const SizedBox(width: 9),
        Text(
          style.label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: style.tint,
          ),
        ),
      ],
    );
  }
}

/// "Not enough days yet" — framed as progress rather than absence: one dot
/// per day needed, filled for each day already logged.
class _LockedCard extends StatelessWidget {
  final DiscoveriesResult result;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _LockedCard({required this.result, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final needed = result.daysNeeded <= 0 ? 7 : result.daysNeeded;
    final logged = result.daysLogged.clamp(0, needed);

    return GlassSurface(
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded, size: 19, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.discoveriesLockedTitle,
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(l10n.discoveriesLockedBody,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.45)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < needed; i++)
                      Container(
                        width: 18,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i < logged ? palette.accent : palette.separator,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.discoveriesLockedProgress(logged, needed),
                      style: AppTypography.caption.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
