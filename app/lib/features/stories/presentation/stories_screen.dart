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
import '../../insights/presentation/insights_screen.dart' show SearchField, CategoryStrip;
import '../domain/life_story.dart';
import 'stories_controller.dart';

/// Where a story's `diagnosisSlug` sits in the catalog tree — resolved
/// against the already-fetched category list, so the feed can show which
/// condition a story is about and filter by it the way the guide does.
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

/// The public story feed, plus the author's own submissions ("Hikayem")
/// behind a second tab on the same screen. Two lists rather than two
/// routes: switching between "what others shared" and "what I submitted"
/// is something people do back and forth while writing their own.
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmWithdraw(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.glassFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.storiesWithdrawTitle,
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        content: Text(l10n.storiesWithdrawBody,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
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
        backgroundColor: palette.glassFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.storiesReportTitle,
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
          cursorColor: palette.accent,
          decoration: InputDecoration(
            hintText: l10n.storiesReportNoteHint,
            hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
          ),
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
      // The floating bottom nav bar (see `HomeShell`) is painted above this
      // screen's own body, so the default FAB position would sit right
      // behind it — lifted by the same clearance every list here pads by.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/settings/stories/new'),
          backgroundColor: palette.accent,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: Text(l10n.storiesWriteCta,
              style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.go('/insights'),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.storiesTitle,
                      style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: _Segmented(
                left: l10n.storiesTabFeed,
                right: l10n.storiesTabMine,
                rightSelected: _showMine,
                palette: palette,
                onSelect: (mine) => setState(() => _showMine = mine),
              ),
            ),
            if (!_showMine) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: SearchField(
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
                  child: CategoryStrip(
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
      ),
    );
  }
}

/// The two-way switch the design uses for feed/mine and for the
/// moderation queue: one muted track, the active half lifted out of it.
class _Segmented extends StatelessWidget {
  final String left;
  final String right;
  final bool rightSelected;
  final AppPalette palette;
  final ValueChanged<bool> onSelect;

  const _Segmented({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.palette,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _half(left, !rightSelected, () => onSelect(false)),
          _half(right, rightSelected, () => onSelect(true)),
        ],
      ),
    );
  }

  Widget _half(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: selected ? palette.glassFill : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTypography.footnote.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? palette.textPrimary : palette.textSecondary,
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 0),
        children: [
          Icon(Icons.auto_stories_outlined, size: 28, color: palette.accent),
          const SizedBox(height: 14),
          Text(
            l10n.storiesFeedEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.storiesFeedEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final story = stories[i];
        final resolved = _resolve(categories, story.diagnosisSlug);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassSurface(
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resolved != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${resolved.category.emoji} ${resolved.disorder.name}',
                      style: AppTypography.caption.copyWith(color: palette.accent),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(story.body,
                    style: AppTypography.subheadline
                        .copyWith(color: palette.textPrimary, fontSize: 14.5, height: 1.65)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat.MMMMd(Localizations.localeOf(context).languageCode).format(story.createdAt)}'
                      ' · ${l10n.storiesAnonymous}',
                      style: AppTypography.caption.copyWith(color: palette.textSecondary),
                    ),
                    InkWell(
                      onTap: () => onReport(story.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(l10n.storiesReport,
                            style: AppTypography.caption
                                .copyWith(color: palette.textSecondary, fontSize: 12)),
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
        StoryStatus.pending => palette.textSecondary,
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
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 0),
        children: [
          Icon(Icons.edit_note_rounded, size: 28, color: palette.accent),
          const SizedBox(height: 14),
          Text(
            l10n.storiesMineEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.storiesMineEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
      itemCount: state.mine.length,
      itemBuilder: (context, i) {
        final story = state.mine[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassSurface(
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _statusLabel(story.status).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: _statusColor(story.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onWithdraw(story.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: palette.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(story.body,
                    style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  DateFormat.MMMMd(Localizations.localeOf(context).languageCode)
                      .format(story.createdAt),
                  style: AppTypography.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
