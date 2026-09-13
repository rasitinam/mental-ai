import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
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
            Row(
              children: [
                SectionLabel(l10n.myProfileStories),
                const Spacer(),
                InkWell(
                  onTap: () => context.push('/settings/my-stories'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(l10n.myProfileStoriesSeeAll,
                        style: AppTypography.footnote.copyWith(color: palette.accent, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StoryHighlights(
              loading: stories.loadingMine,
              stories: stories.mine,
              categories: categories,
              palette: palette,
              l10n: l10n,
              onAdd: () => context.push('/stories/new'),
              onOpen: () => context.push('/settings/my-stories'),
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

/// The one genuinely new visual idea here: a horizontal strip of a
/// person's own stories, styled after Instagram's highlight circles —
/// text stories have no photo to put in one, so each circle carries its
/// diagnosis category's emoji instead, ringed in the story's own
/// moderation status color (see `MyStoriesScreen`'s same status→color
/// mapping) so "still pending" or "needs another look" reads at a glance
/// without opening anything.
class _StoryHighlights extends StatelessWidget {
  final bool loading;
  final List<LifeStory> stories;
  final List<DisorderCategory> categories;
  final AppPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  const _StoryHighlights({
    required this.loading,
    required this.stories,
    required this.categories,
    required this.palette,
    required this.l10n,
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

  Color _ringColor(StoryStatus status) => switch (status) {
        StoryStatus.approved => palette.accent,
        StoryStatus.pending => palette.textTertiary,
        StoryStatus.rejected => palette.warning,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _HighlightCircle(
            label: l10n.myProfileStoriesAdd,
            palette: palette,
            onTap: onAdd,
            ringColor: palette.separator,
            child: Icon(Icons.add_rounded, size: 22, color: palette.accent),
          ),
          if (loading)
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(left: 14, top: 2),
                child: SkeletonBox(width: 60, height: 60, radius: 30),
              )
          else
            for (final story in stories)
              _HighlightCircle(
                label: _resolve(story.diagnosisSlug)?.name ?? l10n.storiesTitle,
                palette: palette,
                onTap: onOpen,
                ringColor: _ringColor(story.status),
                child: Text(_resolve(story.diagnosisSlug)?.emoji ?? '📝', style: const TextStyle(fontSize: 22)),
              ),
        ],
      ),
    );
  }
}

class _HighlightCircle extends StatelessWidget {
  final String label;
  final Widget child;
  final Color ringColor;
  final AppPalette palette;
  final VoidCallback onTap;

  const _HighlightCircle({
    required this.label,
    required this.child,
    required this.ringColor,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.glassFill,
                  border: Border.all(color: ringColor, width: 2),
                ),
                child: child,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: palette.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
