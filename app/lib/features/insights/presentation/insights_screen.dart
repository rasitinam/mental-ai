import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../domain/insight.dart';
import 'insights_controller.dart';

/// The reference guide. Three ways in, in the order people actually reach
/// for them: search when they know what they're looking for, the category
/// strip when they want to browse, and the research feed when they're just
/// reading. Search sits above the strip rather than replacing it — someone
/// who knows the name shouldn't have to scroll twenty categories to find it,
/// and someone who doesn't still gets something to wander through.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final palette = AppPalette.of(context);

    final searching = _query.trim().length >= 2;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _StoriesEntryCard(palette: palette, l10n: l10n),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _SearchField(
              controller: _search,
              palette: palette,
              hint: l10n.guideSearchHint,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _search.clear();
                setState(() => _query = '');
              },
            ),
          ),
          if (!searching)
            _CategoryStrip(
              categories: categories,
              selected: selected,
              palette: palette,
              allLabel: l10n.guideCategoryAll,
              onSelect: (slug) => ref.read(selectedCategoryProvider.notifier).state = slug,
            ),
          Expanded(
            child: searching
                ? _SearchResults(
                    query: _query.trim(),
                    categories: categories,
                    palette: palette,
                    l10n: l10n,
                  )
                : RefreshIndicator(
                    color: palette.accent,
                    onRefresh: controller.load,
                    // Slivers rather than a ListView of children: the feed
                    // grows without bound as research is ingested, and an
                    // eager list would build every card ever synthesized on
                    // the first frame.
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          sliver: SliverList.list(
                            children: [
                              if (selected != null)
                                ..._categorySection(
                                  context: context,
                                  category:
                                      categories.where((c) => c.slug == selected).firstOrNull,
                                  palette: palette,
                                  l10n: l10n,
                                ),
                              if (state.loading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 60),
                                  child: Center(
                                      child: CircularProgressIndicator(color: palette.accent)),
                                )
                              else if (state.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Text(state.error!,
                                      style: TextStyle(color: palette.warning),
                                      textAlign: TextAlign.center),
                                )
                              else if (state.insights.isEmpty)
                                _EmptyFeed(
                                  palette: palette,
                                  inCategory: selected != null,
                                  synthesizing: state.synthesizing,
                                  onSynthesizeNow: controller.synthesizeNow,
                                  l10n: l10n,
                                )
                              else if (selected != null) ...[
                                const SizedBox(height: 22),
                                _SectionLabel(
                                    text: l10n.guideResearchInCategory, palette: palette),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                          sliver: SliverList.builder(
                            itemCount: state.loading || state.error != null
                                ? 0
                                : state.insights.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _InsightCard(insight: state.insights[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categorySection({
    required BuildContext context,
    required DisorderCategory? category,
    required AppPalette palette,
    required AppLocalizations l10n,
  }) {
    if (category == null) return const [];

    return [
      if (category.note != null) ...[
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
                child: Text(category.note!,
                    style: AppTypography.footnote.copyWith(color: palette.warning)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${category.emoji}  ${category.name}',
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration:
                BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(100)),
            child: Text(
              l10n.guideDisorderCount(category.disorders.length),
              style: AppTypography.caption.copyWith(color: palette.accent),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: category.disorders.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, i) => _DisorderCard(
          disorder: category.disorders[i],
          palette: palette,
          subtitle: l10n.guideOpenCard,
          onTap: () => context.go('/insights/disorder/${category.disorders[i].slug}'),
        ),
      ),
    ];
  }
}

/// A direct, hard-to-miss way into the story feed — previously reachable
/// only through Settings → Topluluk, which nobody browsing the guide for
/// research would ever think to check. Sits right under the app bar,
/// above even the search field: the single most visible spot on the
/// screen people already visit to read about their condition.
class _StoriesEntryCard extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;
  const _StoriesEntryCard({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.accent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/settings/stories'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_stories_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storiesEntryTitle,
                      style: AppTypography.headline.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.storiesEntryBody,
                      style: AppTypography.footnote.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.palette,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: palette.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: onClear,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: palette.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Searches the whole catalog at once rather than within the selected
/// category — the point of typing a name is to skip the browsing.
class _SearchResults extends StatelessWidget {
  final String query;
  final List<DisorderCategory> categories;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _SearchResults({
    required this.query,
    required this.categories,
    required this.palette,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final needle = query.toLowerCase();
    final matches = <({DisorderCategory category, Disorder disorder})>[];
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (disorder.name.toLowerCase().contains(needle) ||
            category.name.toLowerCase().contains(needle)) {
          matches.add((category: category, disorder: disorder));
        }
      }
    }

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
        child: Text(
          l10n.guideSearchEmpty(query),
          textAlign: TextAlign.center,
          style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final match = matches[i];
        return GlassSurface(
          radius: 20,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.go('/insights/disorder/${match.disorder.slug}'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(match.category.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.disorder.name,
                            style: AppTypography.subheadline.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 3),
                        Text(match.category.name,
                            style:
                                AppTypography.caption.copyWith(color: palette.textTertiary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: palette.textTertiary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<DisorderCategory> categories;
  final String? selected;
  final AppPalette palette;
  final String allLabel;
  final ValueChanged<String?> onSelect;

  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.palette,
    required this.allLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Twenty-one chips, each a Material with its own ink response —
        // built as they scroll into view rather than all at once.
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: allLabel,
              icon: Icons.apps_rounded,
              selected: selected == null,
              palette: palette,
              onTap: () => onSelect(null),
            );
          }

          final category = categories[index - 1];
          return _CategoryChip(
            label: '${category.emoji} ${category.name}',
            selected: selected == category.slug,
            palette: palette,
            onTap: () => onSelect(category.slug),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? palette.canvasBottom : palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? palette.accent : palette.glassFill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? palette.accent : palette.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTypography.footnote.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisorderCard extends StatelessWidget {
  final Disorder disorder;
  final AppPalette palette;
  final String subtitle;
  final VoidCallback onTap;

  const _DisorderCard({
    required this.disorder,
    required this.palette,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(Icons.psychology_outlined, size: 17, color: palette.accent),
              ),
              const SizedBox(height: 12),
              Text(
                disorder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subheadline.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _SectionLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
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
                child: Text(insight.title,
                    style: AppTypography.headline.copyWith(color: palette.textPrimary)),
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
                    decoration: BoxDecoration(
                        color: palette.accentSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(tag, style: AppTypography.caption.copyWith(color: palette.accent)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                .format(insight.createdAt),
            style: AppTypography.caption.copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final AppPalette palette;
  final bool inCategory;
  final bool synthesizing;
  final VoidCallback onSynthesizeNow;
  final AppLocalizations l10n;

  const _EmptyFeed({
    required this.palette,
    required this.inCategory,
    required this.synthesizing,
    required this.onSynthesizeNow,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GlassSurface(
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 30, color: palette.accent),
            const SizedBox(height: 14),
            Text(
              inCategory ? l10n.guideEmptyInCategory : l10n.guideEmptyFeed,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              inCategory ? l10n.guideEmptyInCategoryBody : l10n.guideEmptyFeedBody,
              textAlign: TextAlign.center,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
            ),
            if (!inCategory) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: AppPrimaryButton(
                  label: l10n.guideSynthesizeNow,
                  loading: synthesizing,
                  onPressed: onSynthesizeNow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
