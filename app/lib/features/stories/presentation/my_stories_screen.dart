import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../domain/life_story.dart';
import 'stories_controller.dart';
import 'story_detail_screen.dart';
import 'story_submit_screen.dart';

/// The author's own submissions, with the moderation status the public
/// feed never shows — as a grid of square previews (one tap opens the
/// full text, see [StoryDetailScreen]), the same "post grid" shape as
/// every photo-sharing app's own profile, adapted to text: each tile
/// carries its diagnosis category's emoji and a few lines of the body
/// instead of a photo. Its own route under Settings rather than a tab on
/// the feed: once the feed became the app's landing screen, a segmented
/// control at the top of it was one decision too many for the screen
/// people open by reflex.
class MyStoriesScreen extends ConsumerStatefulWidget {
  const MyStoriesScreen({super.key});

  @override
  ConsumerState<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends ConsumerState<MyStoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadMine());
  }

  ({String emoji, String name})? _resolve(List<DisorderCategory> categories, String slug) {
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (disorder.slug == slug) return (emoji: category.emoji, name: disorder.name);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StorySubmitScreen()),
          ),
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
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.settingsMyStories,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: palette.accent,
                onRefresh: ref.read(storiesControllerProvider.notifier).loadMine,
                child: _buildBody(state, palette, l10n, categories),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    StoriesState state,
    AppPalette palette,
    AppLocalizations l10n,
    List<DisorderCategory> categories,
  ) {
    if (state.loadingMine) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: 6,
        itemBuilder: (context, i) => SkeletonBox(radius: 8, height: double.infinity),
      );
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: state.mine.length,
      itemBuilder: (context, i) {
        final story = state.mine[i];
        return _StoryTile(
          story: story,
          tag: _resolve(categories, story.diagnosisSlug),
          palette: palette,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StoryDetailScreen(storyId: story.id)),
          ),
        );
      },
    );
  }
}

class _StoryTile extends StatelessWidget {
  final LifeStory story;
  final ({String emoji, String name})? tag;
  final AppPalette palette;
  final VoidCallback onTap;

  const _StoryTile({required this.story, required this.tag, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.glassFill,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tag != null) Text(tag!.emoji, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: storyStatusColor(palette, story.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      story.body,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (story.anonymous)
              Positioned(
                right: 6,
                bottom: 6,
                child: Icon(Icons.visibility_off_rounded, size: 12, color: palette.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
