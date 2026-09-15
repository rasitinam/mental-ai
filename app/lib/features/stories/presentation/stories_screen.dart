import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../insights/presentation/insights_screen.dart' show SearchField, CategoryStrip;
import '../../profile/data/profile_api.dart';
import '../../social/data/dm_badge.dart';
import '../../social/presentation/user_profile_screen.dart' show UserAvatar;
import '../data/life_stories_api.dart' show storyTranslationProvider;
import '../domain/life_story.dart';
import 'metoo.dart';
import 'moderation_controller.dart';
import 'stories_controller.dart';

/// Where a story's `diagnosisSlug` sits in the catalog tree — resolved
/// against the already-fetched category list.
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

/// Hikayeler — the public story feed. Messages sit in its header with
/// their unread dot, and an admin sees the approval queue at the top of
/// the feed instead of hunting for it in settings.
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
    // Non-autoDispose controller: ask again so coming back from moderation
    // shows the stories that were just approved.
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadFeed());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _report(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.storiesReportTitle, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: AppTypography.body.copyWith(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.storiesReportNoteHint,
            hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.storiesReport, style: TextStyle(color: palette.warning)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final note = noteController.text.trim();
    final ok = await ref.read(storiesControllerProvider.notifier).report(id, note: note.isEmpty ? null : note);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? l10n.storiesReportSent : l10n.commonError)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);
    final controller = ref.read(storiesControllerProvider.notifier);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];
    final myUserId = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(myProfileProvider).valueOrNull?.isAdmin ?? false;
    final moderation = isAdmin ? ref.watch(moderationControllerProvider) : null;
    final dmBadge = ref.watch(dmBadgeProvider.select((s) => s.visible));

    // Only categories a story actually exists in.
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

    // The feed's own most-reacted-to stories, from the page already loaded.
    final highlights = [...state.feed.where((s) => s.reactionCount > 0)]
      ..sort((a, b) => b.reactionCount.compareTo(a.reactionCount));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stories/new'),
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(l10n.storiesWriteCta,
            style: AppTypography.label.copyWith(color: palette.onAccent, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            await controller.loadFeed();
            if (isAdmin) await ref.read(moderationControllerProvider.notifier).load();
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.storiesTitle,
                              maxLines: 1,
                              style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                        ),
                        PillButton(
                          icon: Icons.mail_outline_rounded,
                          label: l10n.dmTitle,
                          showDot: dmBadge,
                          onTap: () => context.go('/dm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SearchField(
                      controller: _search,
                      palette: palette,
                      hint: l10n.storiesSearchHint,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
                    if (moderation != null &&
                        (moderation.pending.isNotEmpty || moderation.reports.isNotEmpty)) ...[
                      const SizedBox(height: 12),
                      _AdminBanner(pending: moderation.pending.length, reports: moderation.reports.length),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              if (availableCategories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CategoryStrip(
                      categories: availableCategories,
                      selected: _selectedCategory,
                      palette: palette,
                      allLabel: l10n.guideCategoryAll,
                      onSelect: (slug) => setState(() => _selectedCategory = slug),
                    ),
                  ),
                ),
              if (highlights.isNotEmpty && _query.isEmpty)
                SliverToBoxAdapter(
                  child: _HighlightsStrip(
                    stories: highlights.take(5).toList(),
                    categories: categories,
                    onSelectCategory: (slug) => setState(() => _selectedCategory = slug),
                  ),
                ),
              if (state.loadingFeed)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverList.list(
                    children: const [_StoryCardSkeleton(), _StoryCardSkeleton()],
                  ),
                )
              else if (visibleFeed.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                    child: Column(
                      children: [
                        Icon(Icons.auto_stories_outlined, size: 32, color: palette.textSecondary),
                        const SizedBox(height: 14),
                        Text(l10n.storiesFeedEmpty,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                        const SizedBox(height: 8),
                        Text(l10n.storiesFeedEmptyBody,
                            textAlign: TextAlign.center,
                            style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  // Extra room so the last card clears the share button.
                  padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context, gap: 96)),
                  sliver: SliverList.builder(
                    itemCount: visibleFeed.length,
                    itemBuilder: (context, i) {
                      final story = visibleFeed[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoryCard(
                          story: story,
                          resolved: _resolve(categories, story.diagnosisSlug),
                          myUserId: myUserId,
                          onReport: _report,
                          onReact: controller.setReaction,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBanner extends StatelessWidget {
  final int pending;
  final int reports;
  const _AdminBanner({required this.pending, required this.reports});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final count = pending > 0 ? pending : reports;
    final title = pending > 0 ? l10n.storiesPendingBanner(pending) : l10n.storiesReportsBanner(reports);
    final subtitle = pending > 0 && reports > 0 ? l10n.storiesReportsBanner(reports) : l10n.storiesAdminOnly;

    return Material(
      color: palette.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.textPrimary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/stories/moderation'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(12)),
                child: Text('$count',
                    style: AppTypography.label.copyWith(color: palette.onAccent, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              Text(l10n.storiesReview,
                  style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
              Icon(Icons.chevron_right_rounded, color: palette.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCardSkeleton extends StatelessWidget {
  const _StoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        radius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 150, height: 24, radius: 8),
            SizedBox(height: 14),
            SkeletonBox(height: 14),
            SizedBox(height: 8),
            SkeletonBox(height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 180, height: 14),
            SizedBox(height: 16),
            SkeletonBox(height: 52, radius: 16),
          ],
        ),
      ),
    );
  }
}

/// One card in the feed, with its own "show original" toggle and — only
/// when the story's language differs from the app's — its own translation.
class _StoryCard extends ConsumerStatefulWidget {
  final LifeStory story;
  final ({DisorderCategory category, Disorder disorder})? resolved;
  final String? myUserId;
  final ValueChanged<String> onReport;
  final void Function(String id, String reaction) onReact;

  const _StoryCard({
    required this.story,
    required this.resolved,
    required this.myUserId,
    required this.onReport,
    required this.onReact,
  });

  @override
  ConsumerState<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends ConsumerState<_StoryCard> {
  bool _showOriginal = false;

  Future<void> _toggleMetoo() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(storiesControllerProvider.notifier);
    final story = widget.story;

    if (story.viewerMetoo) {
      await controller.setMetoo(story.id, on: false);
      return;
    }

    final note = await showMetooSheet(context);
    if (note == null || !mounted) return;

    final ok = await controller.setMetoo(story.id, on: true, note: note == metooNoNote ? null : note);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ok ? l10n.metooSent : l10n.commonError)));
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final resolved = widget.resolved;
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final appLanguage = Localizations.localeOf(context).languageCode;
    final needsTranslation = story.language != appLanguage;

    final translation = needsTranslation ? ref.watch(storyTranslationProvider(story.id)) : null;
    final translatedBody = translation?.valueOrNull;
    final showingOriginal = !needsTranslation || _showOriginal || translatedBody == null;
    final bodyToShow = showingOriginal ? story.body : translatedBody;
    final date = DateFormat.MMMMd(appLanguage).format(story.createdAt);

    return GlassSurface(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (resolved != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: palette.peach, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      resolved.disorder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              Text(date, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          if (story.authorUserId == null)
            Text(l10n.storiesAnonymous, style: AppTypography.footnote.copyWith(color: palette.textSecondary))
          else
            InkWell(
              // Your own signed story goes to Ben, not to the "someone else's
              // account" screen with a follow button on it.
              onTap: () => story.authorUserId == widget.myUserId
                  ? context.go('/settings')
                  : context.push('/users/${story.authorUserId}'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(userId: story.authorUserId!, size: 26, hasAvatar: story.authorHasAvatar),
                    const SizedBox(width: 8),
                    Text(story.authorDisplayName ?? '',
                        style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (needsTranslation && translatedBody != null) ...[
            InkWell(
              onTap: () => setState(() => _showOriginal = !_showOriginal),
              borderRadius: BorderRadius.circular(6),
              child: Text(
                showingOriginal ? l10n.storiesShowTranslation : l10n.storiesTranslated,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(bodyToShow, style: AppTypography.body.copyWith(color: palette.textPrimary)),
          if (needsTranslation && translatedBody != null && !showingOriginal) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showOriginal = true),
              borderRadius: BorderRadius.circular(6),
              child: Text(
                l10n.storiesShowOriginal,
                style: AppTypography.footnote.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reaction in storyReactions)
                _ReactionChip(
                  label: _reactionLabel(l10n, reaction),
                  count: story.reactions[reaction] ?? 0,
                  selected: story.viewerReaction == reaction,
                  onTap: () => widget.onReact(story.id, reaction),
                ),
            ],
          ),
          if (!story.isMine) ...[
            const SizedBox(height: 10),
            MetooStrip(count: story.metooCount, active: story.viewerMetoo, onTap: _toggleMetoo),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => widget.onReport(story.id),
              child: Text(l10n.storiesReport,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

String _reactionLabel(AppLocalizations l10n, String reaction) => switch (reaction) {
      'destek' => l10n.storiesReactionDestek,
      'guclusun' => l10n.storiesReactionGuclusun,
      'anliyorum' => l10n.storiesReactionAnliyorum,
      _ => reaction,
    };

/// A reaction by name, not by emoji: picking a different one swaps rather
/// than stacks, and the reader's own pick is filled.
class _ReactionChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ReactionChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = selected ? palette.onAccent : palette.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? palette.accent : palette.canvasTop,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.footnote.copyWith(color: foreground, fontWeight: FontWeight.w600)),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text('$count',
                      style: AppTypography.footnote.copyWith(
                        color: selected ? palette.onAccent : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The feed's most-reacted-to stories. Tapping one filters the feed to its
/// condition — "show me more like this".
class _HighlightsStrip extends StatelessWidget {
  final List<LifeStory> stories;
  final List<DisorderCategory> categories;
  final ValueChanged<String> onSelectCategory;

  const _HighlightsStrip({required this.stories, required this.categories, required this.onSelectCategory});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Text(l10n.storiesHighlightsTitle,
                style: AppTypography.headline.copyWith(color: palette.textPrimary)),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final story = stories[i];
                final resolved = _resolve(categories, story.diagnosisSlug);
                return Material(
                  color: palette.glassFill,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: resolved == null ? null : () => onSelectCategory(resolved.category.slug),
                    child: Container(
                      width: 224,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (resolved != null)
                            Text(resolved.disorder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              story.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.footnote.copyWith(color: palette.textPrimary),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.favorite_border_rounded, size: 15, color: palette.textSecondary),
                              const SizedBox(width: 4),
                              Text('${story.reactionCount}',
                                  style: AppTypography.caption.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
