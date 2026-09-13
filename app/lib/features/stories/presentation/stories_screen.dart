import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../insights/presentation/insights_screen.dart' show SearchField, CategoryStrip;
import '../../social/presentation/user_profile_screen.dart' show UserAvatar;
import '../data/life_stories_api.dart' show storyTranslationProvider;
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

/// The public story feed — the app's landing screen. The author's own
/// submissions live on their own route (`MyStoriesScreen`, reached from
/// Settings) so this stays a single scrollable feed.
class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
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
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadFeed());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    final myUserId = ref.watch(currentUserIdProvider);

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
      // A plain "+" rather than an extended button: the feed is the
      // landing screen, so this sits under the thumb permanently and an
      // extended label would cover a story card's worth of feed.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: FloatingActionButton(
          onPressed: () => context.push('/stories/new'),
          backgroundColor: palette.accent,
          elevation: 3,
          tooltip: l10n.storiesWriteCta,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
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
                  Text(l10n.storiesTitle,
                      style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
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
            Expanded(
              child: RefreshIndicator(
                color: palette.accent,
                onRefresh: controller.loadFeed,
                child: _FeedList(
                  stories: visibleFeed,
                  loading: state.loadingFeed,
                  categories: categories,
                  palette: palette,
                  l10n: l10n,
                  myUserId: myUserId,
                  onReport: (id) => _report(context, ref, id),
                  onUpvote: controller.toggleUpvote,
                ),
              ),
            ),
          ],
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
  final String? myUserId;
  final ValueChanged<String> onReport;
  final ValueChanged<String> onUpvote;

  const _FeedList({
    required this.stories,
    required this.loading,
    required this.categories,
    required this.palette,
    required this.l10n,
    required this.myUserId,
    required this.onReport,
    required this.onUpvote,
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
          child: _StoryCard(
            story: story,
            resolved: resolved,
            myUserId: myUserId,
            palette: palette,
            l10n: l10n,
            onReport: onReport,
            onUpvote: onUpvote,
          ),
        );
      },
    );
  }
}

/// One card in the feed. A `ConsumerStatefulWidget` of its own — rather
/// than inline in `_FeedList`'s `itemBuilder` — because it needs its own
/// "show original" toggle state and, only when the story's detected
/// language differs from the viewer's app language, its own translation
/// fetch (`storyTranslationProvider`, `autoDispose.family` so a long feed
/// doesn't translate every card up front).
class _StoryCard extends ConsumerStatefulWidget {
  final LifeStory story;
  final ({DisorderCategory category, Disorder disorder})? resolved;
  final String? myUserId;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ValueChanged<String> onReport;
  final ValueChanged<String> onUpvote;

  const _StoryCard({
    required this.story,
    required this.resolved,
    required this.myUserId,
    required this.palette,
    required this.l10n,
    required this.onReport,
    required this.onUpvote,
  });

  @override
  ConsumerState<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends ConsumerState<_StoryCard> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final resolved = widget.resolved;
    final palette = widget.palette;
    final l10n = widget.l10n;
    final appLanguage = Localizations.localeOf(context).languageCode;
    final needsTranslation = story.language != appLanguage;

    final translation =
        needsTranslation ? ref.watch(storyTranslationProvider(story.id)) : null;
    final translatedBody = translation?.valueOrNull;
    final showingOriginal = !needsTranslation || _showOriginal || translatedBody == null;
    final bodyToShow = showingOriginal ? story.body : translatedBody;

    return GlassSurface(
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
          if (needsTranslation && translatedBody != null) ...[
            InkWell(
              onTap: () => setState(() => _showOriginal = !_showOriginal),
              borderRadius: BorderRadius.circular(6),
              child: Text(
                showingOriginal ? l10n.storiesShowTranslation : l10n.storiesTranslated,
                style: AppTypography.caption.copyWith(
                  color: palette.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(bodyToShow,
              style: AppTypography.subheadline
                  .copyWith(color: palette.textPrimary, fontSize: 14.5, height: 1.65)),
          if (needsTranslation && translatedBody != null && !showingOriginal) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showOriginal = true),
              borderRadius: BorderRadius.circular(6),
              child: Text(
                l10n.storiesShowOriginal,
                style: AppTypography.caption.copyWith(color: palette.accent),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _UpvoteButton(
                count: story.upvotes,
                voted: story.viewerUpvoted,
                palette: palette,
                onTap: () => widget.onUpvote(story.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: story.authorUserId == null
                    ? Row(
                        children: [
                          // Same silhouette `UserAvatar` falls back to for a
                          // signed author with no photo — an anonymous story
                          // gets that placeholder too, rather than no
                          // avatar at all, so every card lines up the same way.
                          Container(
                            width: 22,
                            height: 22,
                            decoration:
                                BoxDecoration(shape: BoxShape.circle, color: palette.surfaceMuted),
                            child: Icon(Icons.person_rounded, size: 13, color: palette.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat.MMMMd(appLanguage).format(story.createdAt)}'
                            ' · ${l10n.storiesAnonymous}',
                            style: AppTypography.caption.copyWith(color: palette.textSecondary),
                          ),
                        ],
                      )
                    : InkWell(
                        // A signed story you wrote yourself: the profile
                        // route always shows "someone else's account"
                        // chrome (follow button included), which reads as
                        // broken pointed at your own name — send it to
                        // the real profile screen instead.
                        onTap: () => story.authorUserId == widget.myUserId
                            ? context.push('/settings/profile')
                            : context.push('/users/${story.authorUserId}'),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            UserAvatar(
                              userId: story.authorUserId!,
                              size: 22,
                              hasAvatar: story.authorHasAvatar,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              story.authorDisplayName ?? '',
                              style: AppTypography.caption.copyWith(
                                color: palette.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' · ${DateFormat.MMMMd(appLanguage).format(story.createdAt)}',
                              style: AppTypography.caption.copyWith(color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
              ),
              InkWell(
                onTap: () => widget.onReport(story.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(l10n.storiesReport,
                      style: AppTypography.caption.copyWith(color: palette.textSecondary, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// The Reddit-shaped affordance the feed uses: an arrow and a count, no
/// paired downvote. Filled when the reader has voted, so the state is
/// legible without reading the number.
class _UpvoteButton extends StatelessWidget {
  final int count;
  final bool voted;
  final AppPalette palette;
  final VoidCallback onTap;

  const _UpvoteButton({
    required this.count,
    required this.voted,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: voted ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: voted ? palette.accent : palette.separator),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                voted ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
                size: 15,
                color: voted ? palette.accent : palette.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: voted ? palette.accent : palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
