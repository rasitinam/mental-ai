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
import '../domain/life_story.dart';
import 'stories_controller.dart';

/// Where a story's `diagnosisSlug` actually lives in the catalog tree —
/// resolved once per build against the already-fetched category list, so
/// the feed can show "which condition" on each card and filter by it,
/// the same way the guide filters by category.
({DisorderCategory category, Disorder disorder})? _resolve(
  List<DisorderCategory> categories,
  String diagnosisSlug,
) {
  for (final category in categories) {
    for (final disorder in category.disorders) {
      if (disorder.slug == diagnosisSlug) return (category: category, disorder: disorder);
    }
  }
  return null;
}

/// The public guide's story feed, plus the author's own submissions
/// ("Hikayem") behind a second tab on the same screen. Two lists rather
/// than two routes: switching between "what others shared" and "what I
/// submitted" is something people do back and forth while writing their
/// own, so keeping it one screen avoids a round trip through Settings
/// each time.
class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  bool _showMine = false;
  final _search = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // The controller is a regular (non-autoDispose) provider, so it only
    // fetches once for the app's whole lifetime unless asked again — and
    // the most common way back to this screen is "approve something in
    // moderation, then come check the feed", which needs fresher data
    // than whatever was loaded the first time this screen ever opened.
    Future.microtask(() {
      ref.read(storiesControllerProvider.notifier).loadFeed();
      ref.read(storiesControllerProvider.notifier).loadMine();
    });
  }

  Future<void> _confirmWithdraw(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.canvasBottom,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.storiesWithdrawTitle, style: TextStyle(color: palette.textPrimary)),
        content: Text(l10n.storiesWithdrawBody, style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.storiesWithdraw, style: TextStyle(color: palette.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(storiesControllerProvider.notifier).withdraw(id);
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.canvasBottom,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.storiesReportTitle, style: TextStyle(color: palette.textPrimary)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(hintText: l10n.storiesReportNoteHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.storiesReport, style: TextStyle(color: palette.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(storiesControllerProvider.notifier)
          .report(id, note: noteController.text.trim().isEmpty ? null : noteController.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? l10n.storiesReportSent : l10n.commonError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);
    final controller = ref.read(storiesControllerProvider.notifier);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    // Only categories a story actually exists in — a filter strip full of
    // dead chips isn't useful when most of the catalog has no stories yet.
    final availableCategories = <DisorderCategory>[];
    for (final story in state.feed) {
      final resolved = _resolve(categories, story.diagnosisSlug);
      if (resolved != null && !availableCategories.contains(resolved.category)) {
        availableCategories.add(resolved.category);
      }
    }

    final query = _query.trim().toLowerCase();
    final visibleFeed = state.feed.where((story) {
      final resolved = _resolve(categories, story.diagnosisSlug);
      if (_selectedCategory != null && resolved?.category.slug != _selectedCategory) return false;
      if (query.isEmpty) return true;
      return (resolved?.disorder.name.toLowerCase().contains(query) ?? false) ||
          (resolved?.category.name.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiesTitle)),
      // The floating bottom nav bar (see `HomeShell`) is painted above this
      // screen's own body, so the default FAB position would sit right
      // behind it — lifted by the same clearance every list in the app
      // already pads its bottom content by.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/settings/stories/new'),
          backgroundColor: palette.accent,
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          label: Text(l10n.storiesWriteCta, style: const TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: l10n.storiesTabFeed,
                    selected: !_showMine,
                    palette: palette,
                    onTap: () => setState(() => _showMine = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentButton(
                    label: l10n.storiesTabMine,
                    selected: _showMine,
                    palette: palette,
                    onTap: () => setState(() => _showMine = true),
                  ),
                ),
              ],
            ),
          ),
          if (!_showMine) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SearchField(
                controller: _search,
                palette: palette,
                hint: l10n.storiesSearchHint,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            if (availableCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryStrip(
                  categories: availableCategories,
                  selected: _selectedCategory,
                  palette: palette,
                  allLabel: l10n.guideCategoryAll,
                  onSelect: (slug) => setState(() => _selectedCategory = slug),
                ),
              ),
          ],
          Expanded(
            child: RefreshIndicator(
              color: palette.accent,
              onRefresh: _showMine ? controller.loadMine : controller.loadFeed,
              child: _showMine
                  ? _MineList(
                      state: state,
                      palette: palette,
                      l10n: l10n,
                      onWithdraw: (id) => _confirmWithdraw(context, ref, id),
                    )
                  : _FeedList(
                      stories: visibleFeed,
                      loading: state.loadingFeed,
                      categories: categories,
                      palette: palette,
                      l10n: l10n,
                      onReport: (id) => _report(context, ref, id),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: selected ? palette.canvasBottom : palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
    final fg = selected ? palette.canvasBottom : palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? palette.accent : palette.glassFill,
        shape: StadiumBorder(side: BorderSide(color: selected ? palette.accent : palette.glassBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(label, style: AppTypography.footnote.copyWith(color: fg)),
          ),
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  final List<LifeStory> stories;
  final bool loading;
  final List<DisorderCategory> categories;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ValueChanged<String> onReport;

  const _FeedList({
    required this.stories,
    required this.loading,
    required this.categories,
    required this.palette,
    required this.l10n,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    if (stories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
        children: [
          Icon(Icons.auto_stories_outlined, size: 30, color: palette.accent),
          const SizedBox(height: 14),
          Text(
            l10n.storiesFeedEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.storiesFeedEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final story = stories[i];
        final resolved = _resolve(categories, story.diagnosisSlug);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassSurface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resolved != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${resolved.category.emoji} ${resolved.disorder.name}',
                      style: AppTypography.caption.copyWith(color: palette.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(story.body, style: AppTypography.body.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(story.createdAt),
                      style: AppTypography.caption.copyWith(color: palette.textTertiary),
                    ),
                    InkWell(
                      onTap: () => onReport(story.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_outlined, size: 14, color: palette.textTertiary),
                            const SizedBox(width: 4),
                            Text(l10n.storiesReport,
                                style: AppTypography.caption.copyWith(color: palette.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MineList extends StatelessWidget {
  final StoriesState state;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ValueChanged<String> onWithdraw;

  const _MineList({
    required this.state,
    required this.palette,
    required this.l10n,
    required this.onWithdraw,
  });

  String _statusLabel(StoryStatus status) => switch (status) {
        StoryStatus.pending => l10n.storiesStatusPending,
        StoryStatus.approved => l10n.storiesStatusApproved,
        StoryStatus.rejected => l10n.storiesStatusRejected,
      };

  Color _statusColor(StoryStatus status) => switch (status) {
        StoryStatus.pending => palette.warning,
        StoryStatus.approved => palette.accent,
        StoryStatus.rejected => palette.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    if (state.loadingMine) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    if (state.mine.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
        children: [
          Icon(Icons.edit_note_rounded, size: 30, color: palette.accent),
          const SizedBox(height: 14),
          Text(
            l10n.storiesMineEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.storiesMineEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: state.mine.length,
      itemBuilder: (context, i) {
        final story = state.mine[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassSurface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(story.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _statusLabel(story.status),
                        style: AppTypography.caption.copyWith(color: _statusColor(story.status)),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onWithdraw(story.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: palette.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(story.body, style: AppTypography.body.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 10),
                Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(story.createdAt),
                  style: AppTypography.caption.copyWith(color: palette.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
