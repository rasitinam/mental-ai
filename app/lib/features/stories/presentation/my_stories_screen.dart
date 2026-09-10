import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/life_story.dart';
import 'stories_controller.dart';

/// The author's own submissions, with the moderation status the public
/// feed never shows. Its own route under Settings rather than a tab on
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

  Future<void> _confirmWithdraw(String id) async {
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

  String _statusLabel(AppLocalizations l10n, StoryStatus status) => switch (status) {
        StoryStatus.pending => l10n.storiesStatusPending,
        StoryStatus.approved => l10n.storiesStatusApproved,
        StoryStatus.rejected => l10n.storiesStatusRejected,
      };

  Color _statusColor(AppPalette palette, StoryStatus status) => switch (status) {
        StoryStatus.pending => palette.textSecondary,
        StoryStatus.approved => palette.accent,
        StoryStatus.rejected => palette.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);

    return Scaffold(
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
                child: _buildList(state, palette, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(StoriesState state, AppPalette palette, AppLocalizations l10n) {
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
                        _statusLabel(l10n, story.status).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: _statusColor(palette, story.status),
                        ),
                      ),
                    ),
                    if (story.anonymous) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l10n.storiesAnonymous.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: () => _confirmWithdraw(story.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: palette.warning),
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
