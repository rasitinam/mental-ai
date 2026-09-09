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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];
    final palette = AppPalette.of(context);

    final searching = _query.trim().length >= 2;
    final category = categories.where((c) => c.slug == selected).firstOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.guideTitle,
                        style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: _StoriesEntryCard(palette: palette, l10n: l10n),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: SearchField(
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
              CategoryStrip(
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
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                            sliver: SliverList.list(
                              children: [
                                if (category != null) ...[
                                  if (category.note != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: palette.surfaceMuted,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(category.note!,
                                          style: AppTypography.footnote
                                              .copyWith(color: palette.textSecondary)),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: category.disorders.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      mainAxisExtent: 104,
                                    ),
                                    itemBuilder: (context, i) => _DisorderCard(
                                      disorder: category.disorders[i],
                                      palette: palette,
                                      subtitle: l10n.guideOpenCard,
                                      onTap: () => context
                                          .go('/insights/disorder/${category.disorders[i].slug}'),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                ],
                                if (state.loading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                        child:
                                            CircularProgressIndicator(color: palette.accent)),
                                  )
                                else if (state.error != null)
                                  Text(state.error!,
                                      style: TextStyle(color: palette.warning),
                                      textAlign: TextAlign.center)
                                else if (state.insights.isEmpty)
                                  _EmptyFeed(
                                    palette: palette,
                                    inCategory: selected != null,
                                    synthesizing: state.synthesizing,
                                    onSynthesizeNow: controller.synthesizeNow,
                                    l10n: l10n,
                                  )
                                else ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SectionLabel(selected != null
                                          ? l10n.guideResearchInCategory
                                          : l10n.guideResearchFeed),
                                      InkWell(
                                        onTap: state.synthesizing
                                            ? null
                                            : controller.synthesizeNow,
                                        child: Text(
                                          l10n.guideSynthesizeNow,
                                          style: AppTypography.footnote.copyWith(
                                            color: palette.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
                            sliver: SliverList.builder(
                              itemCount: state.loading || state.error != null
                                  ? 0
                                  : state.insights.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
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
      ),
    );
  }
}

/// A direct, hard-to-miss way into the story feed — previously reachable
/// only through Settings → Topluluk, which nobody browsing the guide for
/// research would ever think to check.
class _StoriesEntryCard extends StatelessWidget {
  final AppPalette palette;
  final AppLocalizations l10n;
  const _StoriesEntryCard({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.accent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/settings/stories'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_stories_outlined, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.storiesEntryTitle,
                        style: AppTypography.label
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      l10n.storiesEntryBody,
                      style: AppTypography.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.85)),
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

/// The rounded search field the guide and the story feed both use.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    required this.palette,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.separator),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: palette.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.label
                  .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: AppTypography.label
                    .copyWith(color: palette.textTertiary, fontWeight: FontWeight.w400),
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

/// The horizontal category filter shared by the guide and the story feed.
class CategoryStrip extends StatelessWidget {
  final List<DisorderCategory> categories;
  final String? selected;
  final AppPalette palette;
  final String allLabel;
  final ValueChanged<String?> onSelect;

  const CategoryStrip({
    super.key,
    required this.categories,
    required this.selected,
    required this.palette,
    required this.allLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        // Twenty-one chips, each a Material with its own ink response —
        // built as they scroll into view rather than all at once.
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: allLabel,
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
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? palette.accent : palette.glassFill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? palette.accent : palette.separator),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              child: Text(
                label,
                style: AppTypography.footnote.copyWith(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : palette.textPrimary,
                ),
              ),
            ),
          ),
        ),
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
          style: AppTypography.footnote.copyWith(color: palette.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final match = matches[i];
        return GlassSurface(
          radius: 16,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.go('/insights/disorder/${match.disorder.slug}'),
            borderRadius: BorderRadius.circular(16),
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
                            style: AppTypography.label.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 3),
                        Text(match.category.name,
                            style:
                                AppTypography.caption.copyWith(color: palette.textSecondary)),
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
      radius: 16,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  disorder.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                disorder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: AppTypography.caption
                      .copyWith(color: palette.accent, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
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
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.title,
              style: AppTypography.cardTitle.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 10),
          Text(insight.body,
              style: AppTypography.subheadline
                  .copyWith(color: palette.textSecondary, fontSize: 13.5, height: 1.6)),
          if (insight.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tag in insight.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                        color: palette.surfaceMuted, borderRadius: BorderRadius.circular(100)),
                    child: Text(tag,
                        style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                .format(insight.createdAt),
            style: AppTypography.caption.copyWith(color: palette.textSecondary),
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
      padding: const EdgeInsets.only(top: 20),
      child: GlassSurface(
        radius: 18,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 26, color: palette.accent),
            const SizedBox(height: 12),
            Text(
              inCategory ? l10n.guideEmptyInCategory : l10n.guideEmptyFeed,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              inCategory ? l10n.guideEmptyInCategoryBody : l10n.guideEmptyFeedBody,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: palette.textSecondary),
            ),
            if (!inCategory) ...[
              const SizedBox(height: 18),
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
