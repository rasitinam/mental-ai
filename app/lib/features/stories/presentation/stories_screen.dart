import 'dart:math' as math;

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
import '../../social/presentation/block_dialog.dart';
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

/// "bugün", "dün", "3 gün önce", then the date.
String relativeDay(AppLocalizations l10n, DateTime date, String locale) {
  final now = DateTime.now();
  final local = date.toLocal();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) return l10n.storiesToday;
  if (days == 1) return l10n.storiesYesterday;
  if (days < 7) return l10n.storiesDaysAgo(days);
  return DateFormat.MMMMd(locale).format(local);
}

/// Hikayeler — the public story feed. Messages sit in its header with
/// their unread count, and an admin sees the approval queue at the top of
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

  /// The flag on a story card: report it, or block whoever wrote it. Blocking
  /// works for anonymous stories too — the backend resolves the author, the
  /// reader never sees who it was.
  Future<void> _storyActions(String id) async {
    final l10n = AppLocalizations.of(context)!;

    // The app theme makes bottom sheets transparent on purpose; `SheetFrame`
    // supplies the surface, like every other sheet in the app.
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => SheetFrame(
        children: [
          OutlineBlockButton(
            icon: Icons.flag_outlined,
            label: l10n.storiesReport,
            onTap: () => Navigator.of(sheetContext).pop('report'),
          ),
          const SizedBox(height: 10),
          OutlineBlockButton(
            icon: Icons.block_rounded,
            label: l10n.blockAuthorAction,
            onTap: () => Navigator.of(sheetContext).pop('block'),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(l10n.commonClose)),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'report') return _report(id);

    if (!await confirmBlock(context) || !mounted) return;
    final ok = await ref.read(storiesControllerProvider.notifier).blockAuthor(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(ok ? l10n.blockDone : l10n.commonError)));
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
    final unread = ref.watch(dmBadgeProvider.select((s) => s.count));

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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stories/new'),
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(l10n.storiesWriteCta,
            style: AppTypography.label.copyWith(color: palette.onAccent, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.textPrimary,
          onRefresh: () async {
            await controller.loadFeed();
            if (isAdmin) await ref.read(moderationControllerProvider.notifier).load();
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          count: unread,
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
                      const SizedBox(height: 14),
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
                      allLabel: l10n.storiesFilterAll,
                      onSelect: (slug) => setState(() => _selectedCategory = slug),
                    ),
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
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StoryCard(
                          story: story,
                          resolved: _resolve(categories, story.diagnosisSlug),
                          myUserId: myUserId,
                          onReport: _storyActions,
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
    final hasPending = pending > 0;
    final count = hasPending ? pending : reports;
    final label = hasPending ? l10n.storiesPendingLabel : l10n.storiesReportsLabel;
    final subtitle = hasPending && reports > 0 ? l10n.storiesReportsBanner(reports) : l10n.storiesAdminOnly;

    return Semantics(
      button: true,
      label: '$count $label',
      child: Material(
        color: palette.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.textPrimary, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/stories/moderation'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: palette.accent, borderRadius: BorderRadius.circular(11)),
                  child: Text('$count',
                      style: AppTypography.label.copyWith(color: palette.onAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(subtitle, style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.storiesReview,
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, size: 20, color: palette.textPrimary),
              ],
            ),
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
      padding: EdgeInsets.only(bottom: 14),
      child: GlassSurface(
        radius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 150, height: 26, radius: 8),
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

/// One card in the feed: the diagnosis and when, who (or "isimsiz"), four
/// lines of the story — tap to read it all — reactions, and "Bende de oldu".
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
  bool _expanded = false;

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
    final bodyStyle = AppTypography.body.copyWith(color: palette.textPrimary);

    return GlassSurface(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (resolved != null) ...[
                      Flexible(child: TintTag(label: resolved.disorder.name, color: palette.peach)),
                      const SizedBox(width: 10),
                    ],
                    Text(relativeDay(l10n, story.createdAt, appLanguage),
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: l10n.storiesReport,
                  onPressed: () => widget.onReport(story.id),
                  icon: Icon(Icons.flag_outlined, size: 18, color: palette.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(userId: story.authorUserId!, size: 22, hasAvatar: story.authorHasAvatar),
                    const SizedBox(width: 8),
                    Text(story.authorDisplayName ?? '',
                        style: AppTypography.footnote.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 11),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: bodyToShow, style: DefaultTextStyle.of(context).style.merge(bodyStyle)),
                maxLines: 4,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflows = painter.didExceedMaxLines;
              painter.dispose();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: overflows ? () => setState(() => _expanded = !_expanded) : null,
                    child: Text(
                      bodyToShow,
                      maxLines: _expanded ? null : 4,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: bodyStyle,
                    ),
                  ),
                  if (overflows && !_expanded)
                    InkWell(
                      onTap: () => setState(() => _expanded = true),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l10n.pathReadFull,
                          style: AppTypography.footnote.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          const SizedBox(height: 11),
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final reaction in storyReactions) ...[
                  if (reaction != storyReactions.first) const SizedBox(width: 6),
                  _ReactionChip(
                    label: _reactionLabel(l10n, reaction),
                    color: _reactionColor(palette, reaction),
                    count: story.reactions[reaction] ?? 0,
                    selected: story.viewerReaction == reaction,
                    onTap: () => widget.onReact(story.id, reaction),
                  ),
                ],
              ],
            ),
          ),
          if (!story.isMine) ...[
            const SizedBox(height: 11),
            MetooStrip(count: story.metooCount, active: story.viewerMetoo, onTap: _toggleMetoo),
          ],
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

/// Each of the three reactions gets its own vivid color when picked, so a
/// story with several reactions doesn't read as one repeated color —
/// support is green, strength is amber, understanding is purple.
Color _reactionColor(AppPalette palette, String reaction) => switch (reaction) {
      'destek' => palette.vividGreen,
      'guclusun' => palette.vividAmber,
      'anliyorum' => palette.vividPurple,
      _ => palette.vividGreen,
    };

/// A reaction by name: picking a different one swaps rather than stacks,
/// and the reader's own pick is filled. Picking it (not un-picking, and
/// not just re-rendering already-selected) plays a small pop-and-sparkle,
/// the same beat as a YouTube like — a nod that the tap landed, over
/// before it can get in the way of reading.
class _ReactionChip extends StatefulWidget {
  final String label;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.label,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.16, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 70),
  ]).animate(_pop);
  final _burstKey = GlobalKey<_ReactionBurstState>();

  @override
  void didUpdateWidget(covariant _ReactionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _pop.forward(from: 0);
      _burstKey.currentState?.burst();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = widget.selected ? palette.onVivid : palette.textPrimary;

    return Semantics(
      button: true,
      selected: widget.selected,
      child: _ReactionBurst(
        key: _burstKey,
        color: widget.color,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: widget.selected ? widget.color : palette.canvasTop,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label,
                        style: AppTypography.footnote.copyWith(color: foreground, fontWeight: FontWeight.w600)),
                    if (widget.count > 0) ...[
                      const SizedBox(width: 6),
                      Text('${widget.count}',
                          style: AppTypography.footnote.copyWith(
                            color: widget.selected ? palette.onVivid : palette.textSecondary,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A handful of dots in the reaction's own color, popping outward from
/// above the chip and fading — [burst] is called once, externally, right
/// as the chip is picked. Doesn't affect the chip's own layout: the dots
/// draw past its bounds and never take part in hit-testing.
class _ReactionBurst extends StatefulWidget {
  final Color color;
  final Widget child;

  const _ReactionBurst({super.key, required this.color, required this.child});

  @override
  State<_ReactionBurst> createState() => _ReactionBurstState();
}

class _ReactionBurstState extends State<_ReactionBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

  // Angles spread in a fan above the chip, plus a small per-dot size/reach
  // variation so the burst reads as a scatter rather than a neat ring.
  static const _dots = [(-60.0, 0.85), (-28.0, 1.0), (-4.0, 0.7), (18.0, 1.05), (46.0, 0.8), (70.0, 0.95)];

  void burst() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isDismissed) return const SizedBox.shrink();
              final t = Curves.easeOut.transform(_controller.value);
              final fade = 1 - Curves.easeIn.transform(_controller.value);
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  for (final (angleDeg, reach) in _dots) _dot(angleDeg, reach, t, fade),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dot(double angleDeg, double reach, double t, double fade) {
    final rad = angleDeg * math.pi / 180;
    final distance = 26 * reach * t;
    return Transform.translate(
      offset: Offset(math.sin(rad) * distance, -4 - math.cos(rad) * distance),
      child: Opacity(
        opacity: fade,
        child: Container(
          width: 5 + reach,
          height: 5 + reach,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
