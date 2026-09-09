import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/life_story.dart';
import 'stories_controller.dart';

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
                      state: state,
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

class _FeedList extends StatelessWidget {
  final StoriesState state;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ValueChanged<String> onReport;

  const _FeedList({
    required this.state,
    required this.palette,
    required this.l10n,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (state.loadingFeed) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    if (state.feed.isEmpty) {
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
      itemCount: state.feed.length,
      itemBuilder: (context, i) {
        final story = state.feed[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassSurface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
