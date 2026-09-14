import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../../social/data/social_api.dart';
import '../../stories/domain/life_story.dart';
import '../../stories/presentation/stories_controller.dart';
import '../../stories/presentation/story_detail_screen.dart';
import '../../stories/presentation/story_grid_tile.dart';
import '../../stories/presentation/story_submit_screen.dart';
import '../data/profile_api.dart';

/// The account's own landing view for the tab that used to open straight
/// into the settings list — a proper profile now, the way the story feed
/// and follow system already read on everyone else's account (see
/// `UserProfileScreen`), with the actual settings list one tap away
/// behind the gear icon instead of being the first thing this tab shows.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    // `storiesControllerProvider` already loads `mine` for the app's
    // whole lifetime the first time anything reads it — usually this
    // screen, since it's the tab a person lands on by reflex a lot less
    // often than Stories itself. Asking again here just means a person
    // who withdrew or edited a story elsewhere sees that reflected the
    // next time they open this tab, not a stale first load.
    Future.microtask(() => ref.read(storiesControllerProvider.notifier).loadMine());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final myUserId = ref.watch(currentUserIdProvider);
    final profile = ref.watch(myProfileProvider);
    final avatar = ref.watch(avatarBytesProvider);
    final stats = myUserId == null ? null : ref.watch(publicProfileProvider(myUserId));
    final stories = ref.watch(storiesControllerProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          children: [
            Row(
              children: [
                Text(l10n.navProfile, style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                const Spacer(),
                SquareIconButton(
                  icon: Icons.tune_rounded,
                  onPressed: () => context.push('/settings/list'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: GestureDetector(
                onTap: () => context.push('/settings/profile'),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: palette.accent, width: 2)),
                  child: avatar.when(
                    data: (bytes) => Container(
                      width: 92,
                      height: 92,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surfaceMuted),
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover, width: 92, height: 92)
                          : Icon(Icons.person_rounded, size: 46, color: palette.textTertiary),
                    ),
                    loading: () => const SkeletonBox(width: 92, height: 92, radius: 46),
                    error: (_, _) => Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surfaceMuted),
                      child: Icon(Icons.person_rounded, size: 46, color: palette.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: profile.when(
                data: (data) => Text(data.displayName,
                    style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                loading: () => const SkeletonBox(width: 140, height: 19, radius: 6),
                error: (_, _) => Text(l10n.commonError, style: TextStyle(color: palette.warning)),
              ),
            ),
            if (profile.valueOrNull?.email != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(profile.value!.email!,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                _ProfileStat(
                  value: stats?.valueOrNull?.storyCount,
                  label: l10n.profileStatStories,
                  palette: palette,
                  onTap: () => context.push('/settings/my-stories'),
                ),
                _ProfileStat(
                  value: stats?.valueOrNull?.followerCount,
                  label: l10n.profileStatFollowers,
                  palette: palette,
                  onTap: myUserId == null ? null : () => context.push('/users/$myUserId/followers'),
                ),
                _ProfileStat(
                  value: stats?.valueOrNull?.followingCount,
                  label: l10n.profileStatFollowing,
                  palette: palette,
                  onTap: myUserId == null ? null : () => context.push('/users/$myUserId/following'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SecondaryButton(
              label: l10n.myProfileEdit,
              icon: Icons.edit_outlined,
              palette: palette,
              onTap: () => context.push('/settings/profile'),
            ),
            const SizedBox(height: 30),
            SectionLabel(l10n.myProfileStories),
            const SizedBox(height: 12),
            _StoryGrid(
              loading: stories.loadingMine,
              stories: stories.mine,
              categories: categories,
              palette: palette,
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StorySubmitScreen()),
              ),
              onOpen: (id) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => StoryDetailScreen(storyId: id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final int? value;
  final String label;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _ProfileStat({required this.value, required this.label, required this.palette, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              value == null
                  ? const SkeletonBox(width: 26, height: 18, radius: 6)
                  : Text('$value', style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 19)),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppPalette palette;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.icon, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: palette.textPrimary),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The account's own post grid, embedded directly on the profile page
/// rather than behind a "see all" tap — the same 3-across square tiles
/// as the dedicated [MyStoriesScreen] (sharing [StoryGridTile]), laid out
/// with [GridView]'s own scrolling disabled so it grows inline with the
/// rest of the page instead of nesting a second scrollable.
class _StoryGrid extends StatelessWidget {
  final bool loading;
  final List<LifeStory> stories;
  final List<DisorderCategory> categories;
  final AppPalette palette;
  final VoidCallback onAdd;
  final void Function(String storyId) onOpen;

  const _StoryGrid({
    required this.loading,
    required this.stories,
    required this.categories,
    required this.palette,
    required this.onAdd,
    required this.onOpen,
  });

  ({String emoji, String name})? _resolve(String diagnosisSlug) {
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (disorder.slug == diagnosisSlug) return (emoji: category.emoji, name: disorder.name);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      // +1 for the leading "write a new one" tile, always first — loading
      // shows five skeleton squares behind it so the grid's shape doesn't
      // jump once real tiles arrive.
      itemCount: 1 + (loading ? 5 : stories.length),
      itemBuilder: (context, i) {
        if (i == 0) return AddStoryTile(palette: palette, onTap: onAdd);
        if (loading) return SkeletonBox(radius: 8, height: double.infinity);

        final story = stories[i - 1];
        return StoryGridTile(
          story: story,
          tag: _resolve(story.diagnosisSlug),
          palette: palette,
          onTap: () => onOpen(story.id),
        );
      },
    );
  }
}
